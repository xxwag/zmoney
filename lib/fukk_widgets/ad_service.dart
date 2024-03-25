import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  // Initialize variables
  BannerAd? bannerAd;
  RewardedAd? rewardedAd;
  RewardedInterstitialAd? rewardedInterstitialAd;
  bool isBannerAdReady = false;
  bool isRewardedAdReady = false;

  void initBannerAd({
    required Function onBannerAdLoaded,
    required Function onBannerAdFailedToLoad,
  }) {
    bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-4652990815059289/6968524603', // Your Ad Unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          isBannerAdReady = true;
          onBannerAdLoaded(); // Execute the callback
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          isBannerAdReady = false;
          onBannerAdFailedToLoad(); // Execute the callback
          ad.dispose();
        },
      ),
    );
    bannerAd!.load();
  }

  // Method to load Rewarded Ad with callbacks
  void loadRewardedAd({
    required Function onRewardedAdLoaded,
    required Function onRewardedAdFailedToLoad,
  }) {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-4652990815059289/8386402654',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          rewardedAd = ad;
          isRewardedAdReady = true;
          onRewardedAdLoaded(); // Invoke callback when ad is loaded
        },
        onAdFailedToLoad: (LoadAdError error) {
          isRewardedAdReady = false;
          onRewardedAdFailedToLoad(); // Invoke callback when ad fails to load
        },
      ),
    );
  }

  // Updated showRewardedAd method with a completion callback
  Future<void> showRewardedAd({
    required Function onRewardedAdSuccess,
    required Function onRewardedAdFailedToShow,
    required Function onRewardedAdDismissed,
  }) async {
    if (!isRewardedAdReady || rewardedAd == null) return;

    rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        AdService().loadRewardedAd(
          onRewardedAdLoaded: () {
            // Logic to handle when the ad is successfully loaded
          },
          onRewardedAdFailedToLoad: () {
            // Logic to handle when the ad fails to load
          },
        );
// You might need to add callbacks here if you use them for reloading
        onRewardedAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        AdService().loadRewardedAd(
          onRewardedAdLoaded: () {
            // Logic to handle when the ad is successfully loaded
          },
          onRewardedAdFailedToLoad: () {
            // Logic to handle when the ad fails to load
          },
        ); // Add callbacks if used for reloading
        onRewardedAdFailedToShow();
      },
    );

    rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      onRewardedAdSuccess(); // Invoke the success callback
      ad.dispose();
      AdService().loadRewardedAd(
        onRewardedAdLoaded: () {
          // Logic to handle when the ad is successfully loaded
        },
        onRewardedAdFailedToLoad: () {
          // Logic to handle when the ad fails to load
        },
      ); // Reload the ad, remember to provide callbacks if you're using them
    });
  }

  // Method to load Rewarded Interstitial Ad
  void loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-4652990815059289/7189734426',
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          rewardedInterstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {},
      ),
    );
  }

  // Method to show Rewarded Interstitial Ad
  Future<void> showRewardedInterstitialAd() async {
    if (rewardedInterstitialAd == null) return;

    rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        ad.dispose();
        loadRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent:
          (RewardedInterstitialAd ad, AdError error) {
        ad.dispose();
        loadRewardedInterstitialAd();
      },
    );

    rewardedInterstitialAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      // Handle the reward
    });
  }

  // Dispose all ads
  void disposeAds() {
    bannerAd?.dispose();
    rewardedAd?.dispose();
    rewardedInterstitialAd?.dispose();
  }
}
