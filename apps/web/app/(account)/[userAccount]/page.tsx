import { isAdmin, isLoggedIn } from "@/lib/auth";
import { redirect } from "next/navigation";

const UserAccount = async () => {
	// redirect back if user is not logged in
	if (!(await isLoggedIn())) {
		redirect("/");
	}

	const adminCheck = await isAdmin();

	if (!adminCheck.isAdmin) {
		// You can handle different error cases here
		console.error("Not admin:", adminCheck.error);
		// redirect("/");
	}

	// You can use the payload information if needed
	const userAddress = adminCheck.payload?.sub;

	return (
		<div>
			Account Page
			{adminCheck.isAdmin && (
				<div className="container mx-auto p-6">
					<h1 className="text-2xl font-bold mb-6">Admin Dashboard</h1>
					<p className="text-sm text-gray-600">Logged in as: {userAddress}</p>
					{/* Admin content */}
				</div>
			)}
		</div>
	);
};

export default UserAccount;
