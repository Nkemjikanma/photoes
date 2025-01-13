// SPDX-License-identifier: MIT
pragma solidity 0.8.27;

import {AggregatorV2V3Interface} from "@chainlink/contracts/v0.8/shared/interfaces/AggregatorV2V3Interface.sol";

library PriceConverter {
  // AggregatorV2V3Interface internal dataFeed;
  // AggregatorV2V3Interface internal sequencerUptimeFeed;

  uint256 private constant GRACE_PERIOD_TIME = 3600;

  error SequencerDown();
  error GracePeriodNotOver();

  function getUSD(
    AggregatorV2V3Interface priceFeed,
    AggregatorV2V3Interface sequencerUptimeFeed
  ) internal view returns (int256) {
    (, int256 answer, uint256 startedAt, , ) = sequencerUptimeFeed
      .latestRoundData();

    // Answer == 0: Sequencer is up
    // Answer == 1: Sequencer is down
    bool isSequencerUp = answer == 0;
    if (!isSequencerUp) {
      revert SequencerDown();
    }

    // Make sure the grace period has passed after the
    // sequencer is back up.
    uint256 timeSinceUp = block.timestamp - startedAt;
    if (timeSinceUp <= GRACE_PERIOD_TIME) {
      revert GracePeriodNotOver();
    }

    (, int256 price, , , ) = priceFeed.latestRoundData();

    return price;
  }
}
