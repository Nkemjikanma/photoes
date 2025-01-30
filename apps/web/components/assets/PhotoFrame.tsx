import type { SVGProps } from "react";

interface PhotoFrameProps extends SVGProps<SVGSVGElement> {
	size?: number | string;
}
export const PhotoFrame = ({
	size,
	width = size || "24px",
	height = size || "24px",
	...props
}: PhotoFrameProps) => {
	console.log(width, height);
	return (
		<svg
			width={width}
			height={height}
			viewBox="20 10 85 85" // Adjusted viewBox to focus on the frame part
			// or try viewBox="25 15 80 80"
			preserveAspectRatio="xMidYMid meet" // Add this to maintain aspect ratio
			id="Layer_1"
			version="1.1"
			xmlns="http://www.w3.org/2000/svg"
			xmlnsXlink="http://www.w3.org/1999/xlink"
			aria-label="Photo frame icon" // Add this
			role="img" // Add this
			className="[&_.st0]:fill-black [&_.st4]:fill-amber-600 [&_.st5]:fill-white dark:[&_.st0]:fill-zinc-300 dark:[&_.st4]:fill-gray-200"
			{...props}
		>
			<g>
				<g>
					<g>
						<path
							className="st0"
							d="M100.2,83.6H29.6c-1,0-1.9-0.8-1.9-1.9V17.8c0-1,0.8-1.9,1.9-1.9h70.6c1,0,1.9,0.8,1.9,1.9v63.9     C102,82.8,101.2,83.6,100.2,83.6z M31.5,79.8h66.8V19.7H31.5V79.8z"
						/>
					</g>
				</g>
			</g>

			<g>
				<g>
					<g>
						<polygon className="st4" points="29.6,81.7 53.7,49.8 77.7,81.7    " />
					</g>
				</g>

				<g>
					<g>
						<path
							className="st0"
							d="M77.7,83.6H29.6c-0.7,0-1.4-0.4-1.7-1c-0.3-0.6-0.2-1.4,0.2-2l24.1-32c0.7-0.9,2.3-0.9,3,0l24.1,32     c0.4,0.6,0.5,1.3,0.2,2C79.1,83.2,78.4,83.6,77.7,83.6z M33.4,79.8H74l-20.3-27L33.4,79.8z"
						/>
					</g>
				</g>
			</g>

			<g>
				<g>
					<g>
						<path
							className="st0"
							d="M77.7,83.6H29.6c-0.7,0-1.4-0.4-1.7-1c-0.3-0.6-0.2-1.4,0.2-2l24.1-32c0.7-0.9,2.3-0.9,3,0l24.1,32     c0.4,0.6,0.5,1.3,0.2,2C79.1,83.2,78.4,83.6,77.7,83.6z M33.4,79.8H74l-20.3-27L33.4,79.8z"
						/>
					</g>
				</g>
			</g>

			<g>
				<g>
					<g>
						<polygon className="st4" points="52.1,81.7 76.1,49.8 100.2,81.7    " />
					</g>
				</g>

				<g>
					<g>
						<path
							className="st0"
							d="M100.2,83.6H52.1c-0.7,0-1.4-0.4-1.7-1c-0.3-0.6-0.2-1.4,0.2-2l24.1-32c0.7-0.9,2.3-0.9,3,0l24.1,32     c0.4,0.6,0.5,1.3,0.2,2C101.5,83.2,100.9,83.6,100.2,83.6z M55.8,79.8h40.6l-20.3-27L55.8,79.8z"
						/>
					</g>
				</g>
			</g>

			<g>
				<g>
					<g>
						<path
							className="st0"
							d="M100.2,83.6H52.1c-0.7,0-1.4-0.4-1.7-1c-0.3-0.6-0.2-1.4,0.2-2l24.1-32c0.7-0.9,2.3-0.9,3,0l24.1,32     c0.4,0.6,0.5,1.3,0.2,2C101.5,83.2,100.9,83.6,100.2,83.6z M55.8,79.8h40.6l-20.3-27L55.8,79.8z"
						/>
					</g>
				</g>
			</g>

			<g>
				<g>
					<g>
						<circle className="st4" cx="64.9" cy="33" r="9.3" />
					</g>
				</g>
			</g>
		</svg>
	);
};
