import type { SVGProps } from "react";

interface AddButtonProps extends SVGProps<SVGSVGElement> {
	size?: number | string;
}

export const AddButton = ({
	size,
	width = size || "24px",
	height = size || "24px",
	...props
}: AddButtonProps) => {
	return (
		<svg
			xmlns="http://www.w3.org/2000/svg"
			width={width}
			height={height}
			viewBox="0 0 24 24"
			className="stroke-zinc-400 fill-none group-hover:fill-zinc-800 group-active:stroke-zinc-200 group-active:fill-zinc-600 group-active:duration-0 duration-300"
			aria-label="Add icon"
			role="img"
		>
			<path
				d="M12 22C17.5 22 22 17.5 22 12C22 6.5 17.5 2 12 2C6.5 2 2 6.5 2 12C2 17.5 6.5 22 12 22Z"
				strokeWidth="1.5"
			/>
			<path d="M8 12H16" strokeWidth="1.5" />
			<path d="M12 16V8" strokeWidth="1.5" />
		</svg>
	);
};
