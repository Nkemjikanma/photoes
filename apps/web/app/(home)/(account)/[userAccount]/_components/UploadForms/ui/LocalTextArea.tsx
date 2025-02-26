import { Textarea } from "@/components/ui/textarea";
import { type FieldMetadata, getTextareaProps } from "@conform-to/react";
import type { ComponentProps } from "react";

export const LocalTextArea = ({
	meta,
	...props
}: {
	meta: FieldMetadata<string>;
} & ComponentProps<typeof Textarea>) => {
	const textareaProps = getTextareaProps(meta);

	const { key, ...restTextareaProps } = textareaProps;

	return <Textarea {...restTextareaProps} {...props} />;
};
