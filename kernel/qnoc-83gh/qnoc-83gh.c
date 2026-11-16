// SPDX-License-Identifier: GPL-2.0
/*
 * UbuntoARM: qnoc-x1e80100 com banda inicial zero.
 *
 * O probe original (qcom_icc_rpmh_probe, embutido no kernel) não define get_bw,
 * então o núcleo de interconexão vota INT_MAX em todos os nós até o sync_state.
 * No IdeaPad 5 2-in-1 14Q8X9 (83GH, X1P42100) isso reseta a máquina ao registrar
 * o system-noc (interconnect@1680000). Este módulo reusa o driver x1e80100.c inteiro
 * e troca só o probe por uma cópia que começa com banda 0. BCMs keepalive continuam
 * com voto mínimo (bcm-voter.c).
 *
 * zero_init=0 volta ao comportamento original.
 */
#include <linux/of.h>
#include <linux/of_device.h>

#define qcom_icc_rpmh_probe qnoc83gh_probe
#include "x1e80100.c"
#undef qcom_icc_rpmh_probe

static bool zero_init = true;
module_param(zero_init, bool, 0444);
MODULE_PARM_DESC(zero_init, "Banda inicial 0 em vez de INT_MAX (padrão: 1)");

static int qnoc83gh_get_bw(struct icc_node *node, u32 *avg, u32 *peak)
{
	*avg = 0;
	*peak = 0;
	return 0;
}

/* cópia de qcom_icc_rpmh_probe (drivers/interconnect/qcom/icc-rpmh.c, 7.3) sem o bloco
 * de QoS (x1e80100 não tem desc->config) e com get_bw */
int qnoc83gh_probe(struct platform_device *pdev)
{
	const struct qcom_icc_desc *desc;
	struct device *dev = &pdev->dev;
	struct icc_onecell_data *data;
	struct icc_provider *provider;
	struct qcom_icc_node * const *qnodes, *qn;
	struct qcom_icc_provider *qp;
	struct icc_node *node;
	size_t num_nodes, i, j;
	int ret;

	desc = of_device_get_match_data(dev);
	if (!desc)
		return -EINVAL;
	if (desc->config)
		return -EINVAL; /* QoS não suportado nesta cópia */

	qnodes = desc->nodes;
	num_nodes = desc->num_nodes;

	qp = devm_kzalloc(dev, sizeof(*qp), GFP_KERNEL);
	if (!qp)
		return -ENOMEM;

	data = devm_kzalloc(dev, struct_size(data, nodes, num_nodes), GFP_KERNEL);
	if (!data)
		return -ENOMEM;
	data->num_nodes = num_nodes;

	provider = &qp->provider;
	provider->dev = dev;
	provider->set = qcom_icc_set;
	provider->pre_aggregate = qcom_icc_pre_aggregate;
	provider->aggregate = qcom_icc_aggregate;
	provider->xlate_extended = qcom_icc_xlate_extended;
	if (zero_init)
		provider->get_bw = qnoc83gh_get_bw;
	provider->data = data;

	icc_provider_init(provider);

	qp->dev = dev;
	qp->bcms = desc->bcms;
	qp->nodes = desc->nodes;
	qp->num_bcms = desc->num_bcms;
	qp->num_nodes = desc->num_nodes;

	qp->voter = of_bcm_voter_get(qp->dev, NULL);
	if (IS_ERR(qp->voter))
		return PTR_ERR(qp->voter);

	for (i = 0; i < qp->num_bcms; i++)
		qcom_icc_bcm_init(qp->bcms[i], dev);

	for (i = 0; i < num_nodes; i++) {
		qn = qnodes[i];
		if (!qn)
			continue;

		if (!qn->node)
			qn->node = icc_node_create_dyn();

		node = qn->node;
		if (IS_ERR(node)) {
			ret = PTR_ERR(node);
			goto err_remove_nodes;
		}

		ret = icc_node_set_name(node, provider, qn->name);
		if (ret) {
			icc_node_destroy(node->id);
			goto err_remove_nodes;
		}

		node->data = qn;
		icc_node_add(node, provider);

		for (j = 0; j < qn->num_links; j++)
			icc_link_nodes(node, &qn->link_nodes[j]->node);

		data->nodes[i] = node;
	}

	ret = icc_provider_register(provider);
	if (ret)
		goto err_remove_nodes;

	platform_set_drvdata(pdev, qp);

	if (of_get_child_count(dev->of_node) > 0) {
		ret = of_platform_populate(dev->of_node, NULL, NULL, dev);
		if (ret)
			goto err_deregister_provider;
	}

	dev_info(dev, "ubuntoarm: %zu nós, banda inicial %s\n", num_nodes, zero_init ? "0" : "INT_MAX");
	return 0;

err_deregister_provider:
	icc_provider_deregister(provider);
err_remove_nodes:
	icc_nodes_remove(provider);
	return ret;
}
