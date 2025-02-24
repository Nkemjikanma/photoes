"use client";
import type { UploadType } from "@/lib/types";
import type { useForm } from "@conform-to/react";
import { useEffect, useState } from "react";
import type { UploadFormType } from "./UploadForm";
import { UploadCollection } from "./UploadForms";
import { PhotosForm } from "./UploadForms/PhotosForm";
import { ReviewStep } from "./UploadForms/ReviewStep";

interface StepContentProps {
	currentStep: number;
	form: ReturnType<typeof useForm<UploadFormType>>[0];
	fields: ReturnType<typeof useForm<UploadFormType>>[1];
	uploadType: UploadType;
}

export const StepContent = ({ currentStep, form, fields, uploadType }: StepContentProps) => {
	const [isReady, setIsReady] = useState(false);

	useEffect(() => {
		setIsReady(false);
		const timer = setTimeout(() => setIsReady(true), 0);
		return () => clearTimeout(timer);
	}, [currentStep]);

	if (!isReady) {
		return <div className="animate-pulse">{/* Loading state */}</div>;
	}

	switch (currentStep) {
		case 0: // Form
			return (
				<>
					<input type="hidden" name="type" value={uploadType} />
					{uploadType === "single" ? (
						<PhotosForm form={form} fields={fields} type={uploadType} />
					) : (
						<UploadCollection form={form} fields={fields} type={uploadType} />
					)}
				</>
			);
		case 1: // Review
			return <ReviewStep form={form} fields={fields} uploadType={uploadType} />;
		// case 2: // Upload
		// 	return <UploadStep form={form} />;
		// case 3: // Mint
		// 	return <MintStep form={form} />;
		default:
			return null;
	}
};
