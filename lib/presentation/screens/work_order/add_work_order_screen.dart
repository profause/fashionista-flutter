import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc.dart';
import 'package:fashionista/data/models/work_order/bloc/work_order_bloc_state.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_1.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_2.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_3.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_flow_page_4.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddWorkOrderScreen extends StatefulWidget {
  const AddWorkOrderScreen({super.key});

  @override
  State<AddWorkOrderScreen> createState() => _AddWorkOrderScreenState();
}

class _AddWorkOrderScreenState extends State<AddWorkOrderScreen> {
  final PageController _pageController = PageController();
  late UserBloc _userBloc;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {});
    _userBloc = context.read<UserBloc>();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final pages = [
      WorkOrderFlowPage1(onNext: () => nextPage()),
      WorkOrderFlowPage2(onNext: () => nextPage(), onPrev: () => prevPage()),
      WorkOrderFlowPage3(onNext: () => nextPage(), onPrev: () => prevPage()),
      WorkOrderFlowPage4(onNext: () => onSave(), onPrev: () => prevPage()),
    ];
    return BlocProvider(
      create: (_) => WorkOrderBloc(),
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: colorScheme.primary,
          backgroundColor: colorScheme.onPrimary,
          title: Text(
            'Start a new Work Order',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          elevation: 0,
        ),
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          //tag: "getStartedButton",
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return pages[index];
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void prevPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void onSave() {
    final state = context.read<WorkOrderBloc>().state;
    if (state is WorkOrderUpdated) {
      final workorder = state.workorder;
      // Save via FirebaseWorkOrderService
      //sl<FirebaseWorkOrderService>().createWorkOrder(workorder);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
