import { bindings, defineConfig, triggers } from "cf/config";

export default defineConfig({
	worker: {
		name: "r2-tracker",
		compatibilityDate: "2025-04-01",
		entrypoint: "src/index.js",
		triggers: [
			triggers.fetch({
				pattern: "nhanes.kylegrealis.com/*",
				zone: "kylegrealis.com",
			}),
			triggers.fetch({
				pattern: "nascar.kylegrealis.com/*",
				zone: "kylegrealis.com",
			}),
		],
		env: {
			DB: bindings.d1({
				name: "r2-downloads",
				id: "31a99c29-a83c-42e5-b8e9-eeefa02ca073",
			}),
			NHANES_BUCKET: bindings.r2({
				name: "nhanes-data",
			}),
			NASCAR_BUCKET: bindings.r2({
				name: "nascar-data",
			}),
		},
	},
});
