// SPDX-License-Identifier: GPL-2.0
/*
 * UbuntoARM: o kernel do Ubuntu não compila o driver do motor de criptografia (qcrypto), então
 * ninguém pede banda no caminho dele e o qnoc corrigido o deixa em zero. O ADSP usa esse motor
 * para validar o registro de sensores (HMAC). Este módulo só faz o voto que o qcrypto faria.
 */
#include <linux/interconnect.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/platform_device.h>

#define CE_BW_KBPS 393600 /* QCE_DEFAULT_MEM_BANDWIDTH do drivers/crypto/qce */

static int ce_vote_probe(struct platform_device *pdev)
{
	struct icc_path *path = devm_of_icc_get(&pdev->dev, "memory");
	int ret;

	if (IS_ERR(path))
		return dev_err_probe(&pdev->dev, PTR_ERR(path), "sem caminho de interconexão\n");

	ret = icc_set_bw(path, CE_BW_KBPS, CE_BW_KBPS);
	if (ret)
		return dev_err_probe(&pdev->dev, ret, "voto de banda falhou\n");

	platform_set_drvdata(pdev, path);
	dev_info(&pdev->dev, "voto de banda do motor de criptografia: %d kB/s\n", CE_BW_KBPS);
	return 0;
}

static void ce_vote_remove(struct platform_device *pdev)
{
	icc_set_bw(platform_get_drvdata(pdev), 0, 0);
}

static const struct of_device_id ce_vote_of_match[] = {
	{ .compatible = "qcom,x1e80100-qce" },
	{ }
};
MODULE_DEVICE_TABLE(of, ce_vote_of_match);

static struct platform_driver ce_vote_driver = {
	.probe = ce_vote_probe,
	.remove = ce_vote_remove,
	.driver = {
		.name = "ubuntoarm-ce-vote",
		.of_match_table = ce_vote_of_match,
	},
};
module_platform_driver(ce_vote_driver);

MODULE_DESCRIPTION("UbuntoARM: voto de banda do motor de criptografia (X1)");
MODULE_LICENSE("GPL");
