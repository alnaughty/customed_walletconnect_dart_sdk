import 'package:cached_network_image/cached_network_image.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';

import '../components/modal_main_page.dart';
import '../models/wallet.dart';
import '../store/wallet_store.dart';
import '../utils/utils.dart';

class ModalWalletIOSPage extends StatefulWidget {
  const ModalWalletIOSPage({
    required this.uri,
    this.store = const WalletStore(),
    this.walletCallback,
    Key? key,
  }) : super(key: key);

  final String uri;
  final WalletStore store;
  final WalletCallback? walletCallback;

  @override
  State<ModalWalletIOSPage> createState() => _ModalWalletIOSPageState();
}

class _ModalWalletIOSPageState extends State<ModalWalletIOSPage> {
  List<Wallet>? walletData;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await init();
    });
    super.initState();
  }

  Future<void> init() async {
    walletData = await iOSWallets();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cnstrnt) {
      final double width = cnstrnt.maxWidth;
      final double height = cnstrnt.maxHeight;
      return SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                walletData == null
                    ? "Fetching wallets"
                    : 'Choose your preferred wallet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            Expanded(
              child: walletData != null
                  ? walletData!.isNotEmpty
                      ? ListView.separated(
                          shrinkWrap: true,
                          itemBuilder: (_, index) {
                            final Wallet wallet = walletData![index];
                            return ListTile(
                              onTap: () async {
                                widget.walletCallback?.call(wallet);
                                await Utils.iosLaunch(
                                    wallet: wallet, uri: widget.uri);
                              },
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 20,
                                color: Colors.grey,
                              ),
                              title: Text(
                                wallet.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              leading: Container(
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      blurRadius: 3,
                                      spreadRadius: 2,
                                      offset: const Offset(-3, 3),
                                    ),
                                  ],
                                ),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      'https://registry.walletconnect.org/logo/sm/${wallet.id}.jpeg',
                                  height: 40,
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, index) => const Divider(),
                          itemCount: walletData!.length,
                        )
                      : const Center(
                          child: Text(
                            "No available wallet installed in your device.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        )
                  : Center(
                      child: CircularProgressIndicator.adaptive(
                        backgroundColor: Colors.grey.shade200,
                        // color: Colors.grey,
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }

  Future<bool> isAppInstalled(String? id) async {
    if (id == null) return false;
    final List<String> idList = id.split("id=");
    if (idList.length > 1) {
      return await LaunchApp.isAppInstalled(
        androidPackageName: idList[1],
      );
    }
    return false;
  }

  Future<List<Wallet>> iOSWallets() {
    Future<bool> shouldShow(wallet) async =>
        await Utils.openableLink(wallet.mobile.universal) ||
        await Utils.openableLink(wallet.mobile.native) ||
        await Utils.openableLink(wallet.app.ios);

    return widget.store.load().then(
      (wallets) async {
        final filter = <Wallet>[];
        for (final wallet in wallets) {
          if (await shouldShow(wallet)) {
            filter.add(wallet);
          }
        }
        return filter;
      },
    );
  }
}
