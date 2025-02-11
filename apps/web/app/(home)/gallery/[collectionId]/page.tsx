import { CollectionId } from "./_components/CollectionId";

const CollectionPage = ({ params }: { params: { collectionId: string } }) => {
	const { collectionId } = params;

	const getCollection = (collectionId: string) => {};
	return (
		<div className="relative w-screen min-w-96 flex flex-col justify-center items-center h-full mx-auto">
			<CollectionId />
		</div>
	);
};

export default CollectionPage;
