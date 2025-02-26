import { isAdmin, isLoggedIn } from "@/lib/auth";
import { redirect } from "next/navigation";
import { AdminPage } from "./_components/AdminPage";

const UserAccount = async ({ params }: { params: { userAccount: string } }) => {
	const { userAccount } = await params;
	const adminCheck = await isAdmin();
	const userAddress = adminCheck.payload?.sub;

	// redirect back if user is not logged in
	if (!(await isLoggedIn()) || userAccount !== userAddress) {
		redirect("/");
	}

	if (adminCheck.isAdmin) {
		return (
			<div className="border w-10/12">
				<AdminPage />
				{adminCheck.isAdmin && (
					<div className="container mx-auto p-6">
						<h1 className="text-2xl font-bold mb-6">Admin Dashboard</h1>
						<p className="text-sm text-gray-600">Logged in as: {userAddress}</p>
						{/* Admin content */}
					</div>
				)}
			</div>
		);
	}

	if (!adminCheck.isAdmin) {
		// You can handle different error cases here
		console.error("Not admin:", adminCheck.error);
	}

	return (
		<div>
			Account Page
			{adminCheck.isAdmin && (
				<div className="container mx-auto p-6">
					<h1 className="text-2xl font-bold mb-6">User Dashboard</h1>
					<p className="text-sm text-gray-600">Logged in as: {userAddress}</p>
				</div>
			)}
		</div>
	);
};

export default UserAccount;
