import { decryptMsg, encryptMsg, getPublicKeyByPrivate } from "@/lib/utils";

export default function DemoPage() {
  async function hendle() {
    try {
      // create identitiy with key-pairs and address
      const alice = {
        // address: "0xAd2a2F9132d475963453641a3680833c4A1Cd523",
        publicKey: getPublicKeyByPrivate(
          "66ddcea898d9ac261eac727fdda2bc024d47db54e66685c0db81471822b6ee3c"
        ),
        privateKey:
          "66ddcea898d9ac261eac727fdda2bc024d47db54e66685c0db81471822b6ee3c",
      };

      // const alice = EthCrypto.createIdentity();

      const secretMessage = "My name is Satoshi Buterin";
      const encrypted = await encryptMsg(
        alice.publicKey, // encrypt with alice's publicKey
        secretMessage
      );

      const decrypted = await decryptMsg(alice.privateKey, encrypted);

      if (decrypted === secretMessage) {
        console.log("success");
        console.log({ alice });
      }
    } catch (error) {
      console.log(error);
    }
  }

  return (
    <>
      <div>
        <button className="py-1 px-3 rounded-lg bg-green-400" onClick={hendle}>
          This is the demo click
        </button>
      </div>
    </>
  );
}
