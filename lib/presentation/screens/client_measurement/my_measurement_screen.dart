import 'dart:async';

import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/clients/my_measurement_model.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/screens/client_measurement/measurement_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/service_locator/service_locator.dart';

class MyMeasurementScreen extends StatefulWidget {
  const MyMeasurementScreen({super.key});

  @override
  State<MyMeasurementScreen> createState() => _MyMeasurementScreenState();
}

class _MyMeasurementScreenState extends State<MyMeasurementScreen> {
  late UserBloc _userBloc;
  final ValueNotifier<List<MyMeasurement>> myMeasurementsNotifier =
      ValueNotifier<List<MyMeasurement>>([]);
  Timer? _debounce;
  bool loadingMeasurements = true;
  @override
  void initState() {
    _userBloc = context.read<UserBloc>();
    _loadMeasurements();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<MyMeasurement>>(
      key: ValueKey(_userBloc.state.uid),
      valueListenable: myMeasurementsNotifier,
      builder: (context, myMeasurements, _) {
        final hasMeasurements = myMeasurements.isNotEmpty;

        return DefaultTabController(
          length: hasMeasurements ? myMeasurements.length : 1,
          child: Scaffold(
            backgroundColor: context.canvasBackground,
            appBar: AppBar(
              automaticallyImplyLeading: true,
              foregroundColor: context.onCanvasText,
              backgroundColor: context.cardSurface,
              title: const Text('My Measurement'),
              elevation: 0,
              actions: [
                if (hasMeasurements)
                  Builder(
                    builder: (context) {
                      final tabController = DefaultTabController.of(context);
                      return AnimatedBuilder(
                        animation: tabController,
                        builder: (context, _) {
                          final selectedIndex = tabController.index
                              .clamp(0, myMeasurements.length - 1);
                          final selectedGroup = myMeasurements[selectedIndex];

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Tooltip(
                                message: 'Copy measurements',
                                child: CustomIconButtonRounded(
                                  size: 18,
                                  iconData: Icons.share_outlined,
                                  onPressed: () =>
                                      _showShareBottomSheet(selectedGroup),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Tooltip(
                                message: selectedGroup.isDefault
                                    ? 'Default client'
                                    : 'Set as default',
                                child: CustomIconButtonRounded(
                                  size: 18,
                                  iconData: selectedGroup.isDefault
                                      ? Icons.star
                                      : Icons.star_outline,
                                  icon: Icon(
                                    selectedGroup.isDefault
                                        ? Icons.star
                                        : Icons.star_outline,
                                    size: 18,
                                    color: selectedGroup.isDefault
                                        ? context.accent
                                        : context.secondaryLabel,
                                  ),
                                  onPressed: selectedGroup.isDefault
                                      ? () {}
                                      : () =>
                                            _setDefaultClient(selectedGroup),
                                  backgroundColor: selectedGroup.isDefault
                                      ? context.accent.withValues(alpha: 0.12)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          );
                        },
                      );
                    },
                  ),
              ],
              bottom: hasMeasurements
                  ? TabBar(
                      isScrollable: true,
                      tabs: [
                        for (var index = 0;
                            index < myMeasurements.length;
                            index++)
                          Tab(
                            text: _tabLabel(myMeasurements[index], index),
                          ),
                      ],
                    )
                  : null,
            ),
            body: _buildBody(myMeasurements),
          ),
        );
      },
    );
  }

  Widget _buildBody(List<MyMeasurement> myMeasurements) {
    if (myMeasurements.isEmpty && loadingMeasurements) {
      return const Center(
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (myMeasurements.isEmpty) {
      return Center(
        child: PageEmptyWidget(
          title: 'No measurements found',
          subtitle: '',
          icon: Icons.straighten,
          iconSize: 48,
        ),
      );
    }

    return TabBarView(
      children: [
        for (final group in myMeasurements)
          group.measurements.isEmpty
              ? Center(
                  child: PageEmptyWidget(
                    title: 'No measurements found',
                    subtitle: '',
                    icon: Icons.straighten,
                    iconSize: 48,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: group.measurements.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => MeasurementInfoCardWidget(
                    client: Client.empty().copyWith(uid: group.uid),
                    measurement: group.measurements[index],
                    onDelete: () {},
                    onEdit: () {},
                    showActions: false,
                  ),
                ),
      ],
    );
  }

  String _tabLabel(MyMeasurement group, int index) {
    final designerName = group.designer.businessName.trim().isNotEmpty
        ? group.designer.businessName.trim()
        : group.designer.name.trim();
    final label = designerName.isEmpty ? 'Designer ${index + 1}' : designerName;
    return group.isDefault ? '$label · Default' : label;
  }

  Future<void> _showShareBottomSheet(MyMeasurement group) async {
    if (group.measurements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No measurements to share')),
      );
      return;
    }

    final designersFuture = _loadShareableDesigners();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FutureBuilder<List<Designer>>(
        future: designersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SafeArea(
              child: SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return SafeArea(
              child: SizedBox(
                height: 240,
                child: Center(
                  child: Text('Could not load designers: ${snapshot.error}'),
                ),
              ),
            );
          }

          return _ShareMeasurementsBottomSheet(
            designers: snapshot.data ?? const [],
            onShare: (designers) =>
                _shareMeasurementsWithDesigners(group, designers),
          );
        },
      ),
    );
  }

  Future<List<Designer>> _loadShareableDesigners() async {
    final mobileNumber = _userBloc.state.mobileNumber.trim();
    if (mobileNumber.isEmpty) {
      throw Exception('Your mobile number is missing from your profile.');
    }

    final clientsResult = await sl<FirebaseClientsService>()
        .findClientByMobileNumber(mobileNumber);
    final existingDesignerIds = clientsResult.fold<Set<String>>(
      (failure) => throw Exception(failure),
      (clients) => clients.map((client) => client.createdBy).toSet(),
    );

    final designersResult = await sl<FirebaseDesignersService>()
        .findDesignersWithFilter(50, 'created_date');
    return designersResult.fold<List<Designer>>(
      (failure) => throw Exception(failure),
      (designers) => designers
          .where((designer) => !existingDesignerIds.contains(designer.uid))
          .toList(),
    );
  }

  Future<bool> _shareMeasurementsWithDesigners(
    MyMeasurement group,
    List<Designer> designers,
  ) async {
    final user = _userBloc.state;
    final userId = user.uid;
    if (userId == null || userId.isEmpty || designers.isEmpty) return false;

    var sharedCount = 0;
    final failures = <String>[];
    final clientsService = sl<FirebaseClientsService>();

    for (final designer in designers) {
      final client = Client.empty().copyWith(
        uid: const Uuid().v4(),
        createdBy: designer.uid,
        fullName: user.fullName,
        mobileNumber: user.mobileNumber,
        imageUrl: user.profileImage,
        gender: user.gender,
        createdDate: DateTime.now(),
        measurements: group.measurements,
      );

      final createResult = await clientsService.addClientToFirestore(client);
      final createFailure = createResult.fold<String?>(
        (failure) => failure.toString(),
        (_) => null,
      );
      if (createFailure != null) {
        failures.add('${designer.name}: $createFailure');
        continue;
      }

      final linkResult = await clientsService.linkClientToUser(
        userId: userId,
        clientId: client.uid,
        designerId: designer.uid,
      );
      final linkFailure = linkResult.fold<String?>(
        (failure) => failure,
        (_) => null,
      );
      if (linkFailure != null) {
        await clientsService.deleteClientById(client.uid);
        failures.add('${designer.name}: $linkFailure');
        continue;
      }

      sharedCount++;
    }

    if (!mounted) return false;
    if (sharedCount > 0) {
      _loadMeasurements();
    }

    if (failures.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sharedCount == 0
                ? 'Could not share measurements: ${failures.join('; ')}'
                : 'Shared with $sharedCount designer(s); ${failures.length} failed.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shared with $sharedCount designer(s)')),
      );
    }

    return sharedCount > 0;
  }

  Future<void> _setDefaultClient(MyMeasurement group) async {
    final userId = _userBloc.state.uid;
    if (userId == null || userId.isEmpty) return;

    final result = await sl<FirebaseClientsService>().setDefaultClientForUser(
      userId: userId,
      clientId: group.uid,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure)),
        );
      },
      (_) {
        myMeasurementsNotifier.value = myMeasurementsNotifier.value
            .map(
              (item) => item.copyWith(isDefault: item.uid == group.uid),
            )
            .toList();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default client updated')),
        );
      },
    );
  }

  Future<void> _loadMeasurements() async {
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      loadingMeasurements = true;
      final result = await sl<FirebaseClientsService>()
          .findMyMeasurements(_userBloc.state.uid!);
      await result.fold(
        (failure) async {
          debugPrint("measurement fetch failed: $failure");
          loadingMeasurements = false;
        },
        (measurements) async {
          if (measurements.isEmpty) {
            myMeasurementsNotifier.value = [];
            loadingMeasurements = false;
            return;
          }

          myMeasurementsNotifier.value = measurements;
          loadingMeasurements = false;
        },
      );
    });
  }

  @override
  void dispose() {
    myMeasurementsNotifier.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

class _ShareMeasurementsBottomSheet extends StatefulWidget {
  final List<Designer> designers;
  final Future<bool> Function(List<Designer> designers) onShare;

  const _ShareMeasurementsBottomSheet({
    required this.designers,
    required this.onShare,
  });

  @override
  State<_ShareMeasurementsBottomSheet> createState() =>
      _ShareMeasurementsBottomSheetState();
}

class _ShareMeasurementsBottomSheetState
    extends State<_ShareMeasurementsBottomSheet> {
  final _searchController = TextEditingController();
  final _selectedDesignerIds = <String>{};
  bool _isSharing = false;
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final filteredDesigners = widget.designers.where((designer) {
      final query = _searchText.toLowerCase();
      return designer.name.toLowerCase().contains(query) ||
          designer.businessName.toLowerCase().contains(query) ||
          designer.mobileNumber.toLowerCase().contains(query);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          top: 12,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                    color: context.softBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Share Measurements',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.onCanvasText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${_selectedDesignerIds.length} selected',
                    style: TextStyle(color: context.secondaryLabel),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchText = value),
                decoration: InputDecoration(
                  hintText: 'Search designers',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: context.iconSubstrate,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.hairline),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filteredDesigners.isEmpty
                    ? Center(
                        child: Text(
                          widget.designers.isEmpty
                              ? 'No new designers available to share with'
                              : 'No matching designers',
                          style: TextStyle(color: context.secondaryLabel),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filteredDesigners.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: context.hairline),
                        itemBuilder: (context, index) {
                          final designer = filteredDesigners[index];
                          final isSelected = _selectedDesignerIds.contains(
                            designer.uid,
                          );
                          final displayName = designer.businessName.isNotEmpty
                              ? designer.businessName
                              : designer.name;

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: _isSharing
                                ? null
                                : (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedDesignerIds.add(designer.uid);
                                      } else {
                                        _selectedDesignerIds.remove(
                                          designer.uid,
                                        );
                                      }
                                    });
                                  },
                            title: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: designer.businessName.isNotEmpty &&
                                    designer.name.isNotEmpty
                                ? Text(designer.name)
                                : null,
                            secondary: CircleAvatar(
                              child: Text(
                                displayName.isEmpty
                                    ? '?'
                                    : displayName[0].toUpperCase(),
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _isSharing || _selectedDesignerIds.isEmpty
                      ? null
                      : _submit,
                  child: _isSharing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Share with ${_selectedDesignerIds.length}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSharing = true);
    final selectedDesigners = widget.designers
        .where((designer) => _selectedDesignerIds.contains(designer.uid))
        .toList();
    final shared = await widget.onShare(selectedDesigners);
    if (!mounted) return;

    if (shared) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isSharing = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
