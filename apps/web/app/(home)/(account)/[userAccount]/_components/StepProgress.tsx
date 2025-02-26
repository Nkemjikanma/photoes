import { Progress } from "@/components/ui/progress";

interface StepProgressProps {
	steps: string[];
	currentStep: number;
}

export const StepProgress = ({ steps, currentStep }: StepProgressProps) => {
	return (
		<div>
			{" "}
			<div>
				<div className="flex justify-between mb-2 max-w-4xl">
					{steps.map((step, index) => (
						<div
							key={step}
							className={`text-sm ${
								index === currentStep ? "text-primary" : "text-muted-foreground"
							}`}
						>
							{step}
						</div>
					))}
				</div>
				<Progress value={(currentStep / (steps.length - 1)) * 100} className="w-full" />
			</div>
		</div>
	);
};
