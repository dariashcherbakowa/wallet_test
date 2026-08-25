import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:wallet_test/core/theme/app_tokens.dart';
import 'package:wallet_test/features/address/address_display.dart';
import 'package:wallet_test/features/address/address_tile_bloc.dart';

class AddressTile extends StatefulWidget {
  const AddressTile({
    super.key,
    required this.address,
    required this.network,
    this.bloc,
  });

  final String address;
  final String network;
  final AddressTileBloc? bloc;

  @override
  State<AddressTile> createState() => _AddressTileState();
}

class _AddressTileState extends State<AddressTile> {
  late final AddressTileBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = widget.bloc ?? GetIt.instance<AddressTileBloc>();
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;

    return Container(
      height: AppTokens.cellHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.horizontalPadding,
      ),
      color: AppTokens.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.network,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTokens.verticalGap),
                Flexible(
                  child: Text(
                    formatAddressForCell(widget.address, textScaleFactor),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTokens.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.gapTextIcon),
          BlocBuilder<AddressTileBloc, AddressTileState>(
            bloc: _bloc,
            builder: (context, state) {
              IconData icon;
              Color color;

              if (state.error != null) {
                icon = Icons.error_outline;
                color = AppTokens.danger;
              } else if (state.copied) {
                icon = Icons.check;
                color = AppTokens.success;
              } else {
                icon = Icons.copy;
                color = AppTokens.textSecondary;
              }

              return SizedBox(
                width: AppTokens.tapTarget,
                height: AppTokens.tapTarget,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    icon,
                    size: AppTokens.iconSize,
                    color: color,
                  ),
                  onPressed: () {
                    _bloc.add(CopyTapped(widget.address));
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
