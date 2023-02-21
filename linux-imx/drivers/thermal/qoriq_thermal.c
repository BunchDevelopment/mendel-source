/*
 * Copyright 2016 Freescale Semiconductor, Inc.
 * Copyright 2017 NXP.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms and conditions of the GNU General Public License,
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 */

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/device_cooling.h>
#include <linux/err.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/thermal.h>
#include <linux/slab.h>

#include "thermal_core.h"

#define SITES_MAX	16

enum tmu_throttle_id {
	THROTTLE_DEVFREQ = 0,
	THROTTLE_NUM,
};
static const char *const throt_names[] = {
	[THROTTLE_DEVFREQ] = "devfreq",
};

/*
 * QorIQ TMU Registers
 */
struct qoriq_tmu_site_regs {
	u32 tritsr;		/* Immediate Temperature Site Register */
	u32 tratsr;		/* Average Temperature Site Register */
	u8 res0[0x8];
};

struct qoriq_tmu_regs {
	u32 tmr;		/* Mode Register */
#define TMR_DISABLE	0x0
#define TMR_ME		0x80000000
#define TMR_ALPF	0x0c000000
	u32 tsr;		/* Status Register */
	u32 tmtmir;		/* Temperature measurement interval Register */
#define TMTMIR_DEFAULT	0x0000000f
	u8 res0[0x14];
	u32 tier;		/* Interrupt Enable Register */
#define TIER_DISABLE	0x0
	u32 tidr;		/* Interrupt Detect Register */
	u32 tiscr;		/* Interrupt Site Capture Register */
	u32 ticscr;		/* Interrupt Critical Site Capture Register */
	u8 res1[0x10];
	u32 tmhtcrh;		/* High Temperature Capture Register */
	u32 tmhtcrl;		/* Low Temperature Capture Register */
	u8 res2[0x8];
	u32 tmhtitr;		/* High Temperature Immediate Threshold */
	u32 tmhtatr;		/* High Temperature Average Threshold */
	u32 tmhtactr;	/* High Temperature Average Crit Threshold */
	u8 res3[0x24];
	u32 ttcfgr;		/* Temperature Configuration Register */
	u32 tscfgr;		/* Sensor Configuration Register */
	u8 res4[0x78];
	struct qoriq_tmu_site_regs site[SITES_MAX];
	u8 res5[0x9f8];
	u32 ipbrr0;		/* IP Block Revision Register 0 */
	u32 ipbrr1;		/* IP Block Revision Register 1 */
	u8 res6[0x310];
	u32 ttr0cr;		/* Temperature Range 0 Control Register */
	u32 ttr1cr;		/* Temperature Range 1 Control Register */
	u32 ttr2cr;		/* Temperature Range 2 Control Register */
	u32 ttr3cr;		/* Temperature Range 3 Control Register */
};

struct tmu_throttle_params {
	const char *name;
	struct thermal_cooling_device *cdev;
	int max_state;
	bool inited;
};
/*
 * Thermal zone data
 */
struct qoriq_tmu_data {
	struct thermal_zone_device *tz;
	struct qoriq_tmu_regs __iomem *regs;
	int sensor_id;
	bool little_endian;
	struct tmu_throttle_params throt_cfgs[THROTTLE_NUM];
};

static void tmu_write(struct qoriq_tmu_data *p, u32 val, void __iomem *addr)
{
	if (p->little_endian)
		iowrite32(val, addr);
	else
		iowrite32be(val, addr);
}

static u32 tmu_read(struct qoriq_tmu_data *p, void __iomem *addr)
{
	if (p->little_endian)
		return ioread32(addr);
	else
		return ioread32be(addr);
}

static int tmu_get_temp(void *p, int *temp)
{
	u32 val;
	struct qoriq_tmu_data *data = p;

	val = tmu_read(data, &data->regs->site[data->sensor_id].tritsr);
	*temp = (val & 0xff) * 1000;

	return 0;
}

static int qoriq_tmu_get_sensor_id(void)
{
	int ret, id;
	struct of_phandle_args sensor_specs;
	struct device_node *np, *sensor_np;

	np = of_find_node_by_name(NULL, "thermal-zones");
	if (!np)
		return -ENODEV;

	sensor_np = of_get_next_child(np, NULL);
	ret = of_parse_phandle_with_args(sensor_np, "thermal-sensors",
			"#thermal-sensor-cells",
			0, &sensor_specs);
	if (ret) {
		of_node_put(np);
		of_node_put(sensor_np);
		return ret;
	}

	if (sensor_specs.args_count >= 1) {
		id = sensor_specs.args[0];
		WARN(sensor_specs.args_count > 1,
				"%s: too many cells in sensor specifier %d\n",
				sensor_specs.np->name, sensor_specs.args_count);
	} else {
		id = 0;
	}

	of_node_put(np);
	of_node_put(sensor_np);

	return id;
}

static int qoriq_tmu_calibration(struct platform_device *pdev)
{
	int i, val, len;
	u32 range[4];
	const u32 *calibration;
	struct device_node *np = pdev->dev.of_node;
	struct qoriq_tmu_data *data = platform_get_drvdata(pdev);

	if (of_property_read_u32_array(np, "fsl,tmu-range", range, 4)) {
		dev_err(&pdev->dev, "missing calibration range.\n");
		return -ENODEV;
	}

	/* Init temperature range registers */
	tmu_write(data, range[0], &data->regs->ttr0cr);
	tmu_write(data, range[1], &data->regs->ttr1cr);
	tmu_write(data, range[2], &data->regs->ttr2cr);
	tmu_write(data, range[3], &data->regs->ttr3cr);

	calibration = of_get_property(np, "fsl,tmu-calibration", &len);
	if (calibration == NULL || len % 8) {
		dev_err(&pdev->dev, "invalid calibration data.\n");
		return -ENODEV;
	}

	for (i = 0; i < len; i += 8, calibration += 2) {
		val = of_read_number(calibration, 1);
		tmu_write(data, val, &data->regs->ttcfgr);
		val = of_read_number(calibration + 1, 1);
		tmu_write(data, val, &data->regs->tscfgr);
	}

	return 0;
}

static void qoriq_tmu_init_device(struct qoriq_tmu_data *data)
{
	/* Disable interrupt, using polling instead */
	tmu_write(data, TIER_DISABLE, &data->regs->tier);

	/* Set update_interval */
	tmu_write(data, TMTMIR_DEFAULT, &data->regs->tmtmir);

	/* Disable monitoring */
	tmu_write(data, TMR_DISABLE, &data->regs->tmr);
}

static int tmu_get_trend(void *p,
	int trip, enum thermal_trend *trend)
{
	int trip_temp, trip_hyst;
	struct qoriq_tmu_data *data = p;

	if (!data->tz)
		return 0;

	if (!data->tz->ops->get_trip_temp ||
		!data->tz->ops->get_trip_hyst ||
		data->tz->ops->get_trip_temp(data->tz, trip, &trip_temp) ||
		data->tz->ops->get_trip_hyst(data->tz, trip, &trip_hyst)) {
		*trend = THERMAL_TREND_RAISE_FULL;
		return 0;
	}

	if (data->tz->temperature >= (trip_temp - trip_hyst))
		*trend = THERMAL_TREND_RAISE_FULL;
	else
		*trend = THERMAL_TREND_DROP_FULL;

	return 0;
}

static struct thermal_zone_of_device_ops tmu_tz_ops = {
	.get_temp = tmu_get_temp,
	.get_trend = tmu_get_trend,
};

static struct tmu_throttle_params *
find_throttle_cfg_by_name(struct qoriq_tmu_data *qt, const char *name)
{
	unsigned int i;

	for (i = 0; qt->throt_cfgs[i].name && i<THROTTLE_NUM; i++)
		if (!strcmp(qt->throt_cfgs[i].name, name))
			return &qt->throt_cfgs[i];

	return NULL;
}

/**
 * tmu_init_throttle_cdev() - Parse the throttle configurations
 * and register them as cooling devices.
 */
static int tmu_init_throttle_cdev(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct qoriq_tmu_data *qt = dev_get_drvdata(dev);
	struct device_node *np_tc, *np_tcc;
	struct thermal_cooling_device *tcd;
	const char *name;
	u32 val;
	int i, ret = 0;

	for (i = 0; i < THROTTLE_NUM; i++) {
		qt->throt_cfgs[i].name = throt_names[i];
		qt->throt_cfgs[i].inited = false;
	}

	np_tc = of_get_child_by_name(dev->of_node, "throttle-cfgs");
	if (!np_tc) {
		dev_info(dev,
			 "throttle-cfg: no throttle-cfgs"
			 " - use default devfreq cooling device\n");
		tcd = devfreq_cooling_register(NULL, 1);
		if (IS_ERR(tcd)) {
			ret = PTR_ERR(tcd);
			if (ret != -EPROBE_DEFER)
				dev_err(&pdev->dev,
					"failed to register"
					"devfreq cooling device: %d\n",
					ret);
			return ret;
		}
		return 0;
	}

	for_each_child_of_node(np_tc, np_tcc) {
		struct tmu_throttle_params *ttp;
		name = np_tcc->name;
		ttp = find_throttle_cfg_by_name(qt, name);
		if (!ttp) {
			dev_err(dev,
				"throttle-cfg: could not find %s\n", name);
			continue;
		}

		ret = of_property_read_u32(np_tcc, "throttle,max_state", &val);
		if (ret) {
			dev_info(dev,
				 "throttle-cfg: %s: missing throttle max state\n", name);
			continue;
		}
		ttp->max_state = val;

		tcd = devfreq_cooling_register(np_tcc, ttp->max_state);
		of_node_put(np_tcc);
		if (IS_ERR(tcd)) {
			ret = PTR_ERR(tcd);
			dev_err(dev,
				"throttle-cfg: %s: failed to register cooling device\n",
				name);
			continue;
		}
		ttp->cdev = tcd;
		ttp->inited = true;
	}

	of_node_put(np_tc);
	return ret;
}

static int qoriq_tmu_probe(struct platform_device *pdev)
{
	int ret;
	struct qoriq_tmu_data *data;
	struct device_node *np = pdev->dev.of_node;
	u32 site = 0;

	if (!np) {
		dev_err(&pdev->dev, "Device OF-Node is NULL");
		return -ENODEV;
	}

	data = devm_kzalloc(&pdev->dev, sizeof(struct qoriq_tmu_data),
			    GFP_KERNEL);
	if (!data)
		return -ENOMEM;

	platform_set_drvdata(pdev, data);

	data->little_endian = of_property_read_bool(np, "little-endian");

	data->sensor_id = qoriq_tmu_get_sensor_id();
	if (data->sensor_id < 0) {
		dev_err(&pdev->dev, "Failed to get sensor id\n");
		ret = -ENODEV;
		goto err_iomap;
	}

	data->regs = of_iomap(np, 0);
	if (!data->regs) {
		dev_err(&pdev->dev, "Failed to get memory region\n");
		ret = -ENODEV;
		goto err_iomap;
	}

	qoriq_tmu_init_device(data);	/* TMU initialization */

	ret = qoriq_tmu_calibration(pdev);	/* TMU calibration */
	if (ret < 0)
		goto err_tmu;

	data->tz = thermal_zone_of_sensor_register(&pdev->dev, data->sensor_id,
				data, &tmu_tz_ops);
	if (IS_ERR(data->tz)) {
		ret = PTR_ERR(data->tz);
		dev_err(&pdev->dev,
			"Failed to register thermal zone device %d\n", ret);
		goto err_tmu;
	}

	ret = tmu_init_throttle_cdev(pdev);
	if (ret)
		goto err_tmu;

	/* Enable monitoring */
	site |= 0x1 << (15 - data->sensor_id);
	tmu_write(data, site | TMR_ME | TMR_ALPF, &data->regs->tmr);

	return 0;

err_tmu:
	iounmap(data->regs);

err_iomap:
	platform_set_drvdata(pdev, NULL);

	return ret;
}

static int qoriq_tmu_remove(struct platform_device *pdev)
{
	int i;
	struct qoriq_tmu_data *data = platform_get_drvdata(pdev);

	for (i=0; i<THROTTLE_NUM; i++)
		if (data->throt_cfgs[i].inited)
			devfreq_cooling_unregister(data->throt_cfgs[i].cdev);

	thermal_zone_of_sensor_unregister(&pdev->dev, data->tz);

	/* Disable monitoring */
	tmu_write(data, TMR_DISABLE, &data->regs->tmr);

	iounmap(data->regs);
	platform_set_drvdata(pdev, NULL);

	return 0;
}

#ifdef CONFIG_PM_SLEEP
static int qoriq_tmu_suspend(struct device *dev)
{
	u32 tmr;
	struct qoriq_tmu_data *data = dev_get_drvdata(dev);

	/* Disable monitoring */
	tmr = tmu_read(data, &data->regs->tmr);
	tmr &= ~TMR_ME;
	tmu_write(data, tmr, &data->regs->tmr);

	return 0;
}

static int qoriq_tmu_resume(struct device *dev)
{
	u32 tmr;
	struct qoriq_tmu_data *data = dev_get_drvdata(dev);

	/* Enable monitoring */
	tmr = tmu_read(data, &data->regs->tmr);
	tmr |= TMR_ME;
	tmu_write(data, tmr, &data->regs->tmr);

	return 0;
}
#endif

static SIMPLE_DEV_PM_OPS(qoriq_tmu_pm_ops,
			 qoriq_tmu_suspend, qoriq_tmu_resume);

static const struct of_device_id qoriq_tmu_match[] = {
	{ .compatible = "fsl,qoriq-tmu", },
	{ .compatible = "fsl,imx8mq-tmu",},
	{},
};
MODULE_DEVICE_TABLE(of, qoriq_tmu_match);

static struct platform_driver qoriq_tmu = {
	.driver	= {
		.name		= "qoriq_thermal",
		.pm		= &qoriq_tmu_pm_ops,
		.of_match_table	= qoriq_tmu_match,
	},
	.probe	= qoriq_tmu_probe,
	.remove	= qoriq_tmu_remove,
};
module_platform_driver(qoriq_tmu);

MODULE_AUTHOR("Jia Hongtao <hongtao.jia@nxp.com>");
MODULE_DESCRIPTION("QorIQ Thermal Monitoring Unit driver");
MODULE_LICENSE("GPL v2");
