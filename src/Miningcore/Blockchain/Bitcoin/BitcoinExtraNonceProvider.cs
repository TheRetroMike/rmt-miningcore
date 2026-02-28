namespace Miningcore.Blockchain.Bitcoin;

public class BitcoinExtraNonceProvider : ExtraNonceProviderBase
{
    public BitcoinExtraNonceProvider(string poolId, byte? clusterInstanceId) : base(poolId, 8, clusterInstanceId)
    {
    }
}
