import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";
import { type FieldMetadata, unstable_useControl as useControl } from "@conform-to/react";
import { type ComponentProps, type ElementRef, useRef } from "react";

export const LocalSelect = ({
	meta,
	items,
	placeholder,
	...props
}: {
	meta: FieldMetadata<string>;
	items: Array<{ name: string; value: string }>;
	placeholder: string;
} & ComponentProps<typeof Select>) => {
	const selectRef = useRef<ElementRef<typeof SelectTrigger>>(null);
	const control = useControl(meta);

	return (
		<>
			<select
				name={meta.name}
				defaultValue={meta.initialValue ?? ""}
				className="sr-only rounded-none"
				ref={control.register}
				aria-hidden
				tabIndex={-1}
				onFocus={() => {
					selectRef.current?.focus();
				}}
			>
				<option value="" />
				{items.map((option) => (
					<option key={option.value} value={option.value} />
				))}
			</select>

			<Select
				{...props}
				value={control.value ?? ""}
				onValueChange={control.change}
				onOpenChange={(open) => {
					if (!open) {
						control.blur();
					}
				}}
			>
				<SelectTrigger>
					<SelectValue placeholder={placeholder} />
				</SelectTrigger>
				<SelectContent>
					{items.map((item) => {
						return (
							<SelectItem key={item.value} value={item.value}>
								{item.name}
							</SelectItem>
						);
					})}
				</SelectContent>
			</Select>
		</>
	);
};
