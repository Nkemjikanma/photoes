"use server";
import type { UploadFormType } from "@/app/(home)/(account)/[userAccount]/_components/UploadForm";
import { parseWithZod } from "@conform-to/zod";
import { uploadFormSchema } from "../schemas";

export const submitHandler = async (prevState: unknown, formData: FormData) => {
	const intent = formData.get("intent");

	const submission = parseWithZod(formData, {
		schema: uploadFormSchema as any,
	});

	if (submission.status !== "success") {
		return submission.reply();
	}

	switch (intent) {
		case "next":
			// Only validate, don't submit
			return submission.reply();

		case "previous":
			return submission.reply();

		case "submit":
			// Handle actual form submission here
			try {
				// Your submission logic here
				// const result = await submitToDatabase(submission.value);
				// return submission.reply({ status: "success", data: result });
				return {};
			} catch (error) {
				console.log("Error:", error);
				return submission.reply({});
			}

		default:
			return submission.reply();
	}
};

const handleNextStep = (formValue: UploadFormType) => {
	console.log("here");

	console.log("formValue", formValue);
	// const nextStep = currentStep + 1;

	// if (nextStep >= steps.length) return;

	// if (!form.valid) return;

	// if (!formValue || !Array.isArray(formValue.photos)) return;

	// try {
	// 	const processedPhotos = processFormCameraData(formValue.photos as FormPhotoInput[]);

	// 	const processedFormData = {
	// 		...formValue,
	// 		photos: processedPhotos.map(transformPhoto),
	// 	} as UploadFormType;

	// 	updateState({
	// 		formData: processedFormData,
	// 	});

	// 	// Update form value
	// 	form.update({
	// 		value: processedFormData,
	// 	});

	// 	setCurrentStep(nextStep);
	// 	updateURL(nextStep, uploadType);
	// } catch (error) {
	// 	console.error("Error processing form data:", error);
	// }
};
