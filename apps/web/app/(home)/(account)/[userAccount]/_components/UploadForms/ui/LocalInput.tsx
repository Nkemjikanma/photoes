import { Input } from "@/components/ui/input";
import { type FieldMetadata, getInputProps } from "@conform-to/react";
import type { ComponentProps } from "react";

export const LocalInput = ({
	meta,
	type,
	...props
}: {
	meta: FieldMetadata;
	type: Parameters<typeof getInputProps>[1]["type"];
} & ComponentProps<typeof Input>) => {
	const inputProps = getInputProps(meta, { type, ariaAttributes: true });

	const { key, ...restInputProps } = inputProps;

	return <Input {...restInputProps} {...props} />;
};
