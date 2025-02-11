const CollectionPage = ({ params }: { params: { collectionId: string } }) => {
	const { collectionId } = params;

	const getCollection = (collectionId: string) => {};
	return <div>{collectionId}</div>;
};
export default CollectionPage;
