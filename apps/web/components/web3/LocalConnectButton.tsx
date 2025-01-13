import { Button } from "@/components/ui/button";
import { ConnectKitButton } from "connectkit";

export const LocalConnectButton = () => {
	return (
		<ConnectKitButton.Custom>
			{({ isConnected, isConnecting, show, hide, address, ensName, chain }) => {
				const display = ensName ?? address;
				return (
					<Button variant="outline" onClick={show} className="py-2 px-4 rounded-none">
						{isConnected ? display : "Connect"}
					</Button>
				);
			}}
		</ConnectKitButton.Custom>
	);
};
