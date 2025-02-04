import { isLoggedIn } from "@/components/web3/actions/auth";
import { redirect } from "next/navigation";

const UserAccount = async () => {
	// redirect back if user is not logged in
	if (!(await isLoggedIn())) {
		redirect("/");
	}
	return <div>Account Page</div>;
};

export default UserAccount;
