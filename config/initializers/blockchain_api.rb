Peatio::Blockchain.registry[:bitcoin] = Bitcoin::Blockchain
Peatio::Blockchain.registry[:geth] = Ethereum::Blockchain
Peatio::Blockchain.registry[:parity] = Ethereum::Blockchain
Peatio::Blockchain.registry[:dogecoin] = Dogecoin::Blockchain