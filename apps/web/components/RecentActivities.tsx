"use client";
import { Avatar, AvatarFallback, AvatarImage } from "@radix-ui/react-avatar";
import { AnimatePresence, motion } from "framer-motion";

import { useEffect, useState } from "react";
import { Card, CardContent } from "./ui/card";
import { Skeleton } from "./ui/skeleton";

type ActivityType = {
	id: string;
	type: "mint" | "purchase";
	user: string;
	photoName: string;
	timestamp: string;
};

// TODO: Add recent activities update anytime the contract is interacted with - minted or purchased
export function RecentActivities() {
	const [activities, setActivities] = useState<ActivityType[]>([]);
	const [isLoading, setIsLoading] = useState(true);

	useEffect(() => {
		// Simulating an API call
		setTimeout(() => {
			setActivities([
				{
					id: "1",
					type: "mint",
					user: "Contract",
					photoName: "Urban Sunset",
					timestamp: "2 minutes ago",
				},
				{
					id: "2",
					type: "purchase",
					user: "Bob",
					photoName: "Mountain Vista",
					timestamp: "5 minutes ago",
				},
				{
					id: "3",
					type: "mint",
					user: "Contract",
					photoName: "Ocean Breeze",
					timestamp: "10 minutes ago",
				},
			]);
			setIsLoading(false);
		}, 1000);
	}, []);

	return (
		<section className="relative w-screen flex py-12 px-4 md:px-6 bg-gray-50 dark:bg-black">
			<div className="max-w-6xl mx-auto">
				<h4 className="font-normal">Recent Activities</h4>
				<div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-5">
					<AnimatePresence>
						{isLoading
							? Array.from({ length: 3 }).map((_, index) => (
									<Card key={index}>
										<CardContent className="p-4">
											<div className="flex items-center space-x-4">
												<Skeleton className="h-12 w-12" />
												<div className="space-y-2">
													<Skeleton className="h-4 w-[200px]" />
													<Skeleton className="h-4 w-[160px]" />
												</div>
											</div>
										</CardContent>
									</Card>
								))
							: activities.map((activity, index) => (
									<motion.div
										key={activity.id}
										initial={{ opacity: 0, y: 20 }}
										animate={{ opacity: 1, y: 0 }}
										exit={{ opacity: 0, y: -20 }}
										transition={{ duration: 0.5, delay: index * 0.1 }}
									>
										<Card key={activity.id} className="rounded-none border-zinc-600">
											<CardContent className="p-4">
												<div className="flex items-center space-x-4">
													<Avatar className="relative bg-zinc-200 dark:bg-zinc-700 w-24 h-24">
														<AvatarImage src={activity.user} />
														<AvatarFallback className="absolute inset-0 flex items-center justify-center text-lg text-amber-600">
															{activity.user[0]}
														</AvatarFallback>
													</Avatar>
													<div>
														<p className="text-sm font-medium">
															{activity.user} {activity.type === "mint" ? "minted" : "purchased"}{" "}
															{activity.photoName}
														</p>
														<p className="text-sm text-gray-500 dark:text-gray-400">
															{activity.timestamp}
														</p>
													</div>
												</div>
											</CardContent>
										</Card>
									</motion.div>
								))}
					</AnimatePresence>
				</div>
			</div>
		</section>
	);
}
