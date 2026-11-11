import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

class PaginatedListView extends StatefulWidget {
  final ScrollController scrollController;
  final Function(int? offset) onPaginate;
  final int? totalSize;
  final int? offset;
  final Widget itemView;
  final bool enabledPagination;
  final bool reverse;
  /// Items per page as the API reports it (the response's `limit`). Null keeps the
  /// historical assumption of 10.
  final int? limit;
  /// How many screens of loaded content may still be left when the next page is
  /// requested.
  final double preloadScreens;
  const PaginatedListView({super.key, required this.scrollController, required this.onPaginate, required this.totalSize,
    required this.offset, required this.itemView, this.enabledPagination = true, this.reverse = false,
    this.limit, this.preloadScreens = 1,
  });

  @override
  State<PaginatedListView> createState() => _PaginatedListViewState();
}

class _PaginatedListViewState extends State<PaginatedListView> {
  int? _offset;
  late List<int?> _offsetList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _offset = 1;
    _offsetList = [1];

    widget.scrollController.addListener(() {
      if (_isNearEnd(widget.scrollController.position)
          && widget.totalSize != null && !_isLoading && widget.enabledPagination) {
        if(mounted && !ResponsiveHelper.isDesktop(context)) {
          _paginate();
        }
      }
    });
  }

  /// Requests the next page while [PaginatedListView.preloadScreens] screens of
  /// loaded content are still left, so it is usually ready before the customer
  /// reaches the end. Waiting for the exact bottom made the list stop as if it
  /// had ended.
  bool _isNearEnd(ScrollPosition position) => position.extentAfter <= position.viewportDimension * widget.preloadScreens;

  /// Number of pages the API holds for [PaginatedListView.totalSize].
  int _pageCount() {
    final int perPage = (widget.limit != null && widget.limit! > 0) ? widget.limit! : 10;
    return (widget.totalSize! / perPage).ceil();
  }

  void _paginate() async {
    int pageSize = _pageCount();
    if (_offset! < pageSize && !_offsetList.contains(_offset!+1)) {

      setState(() {
        _offset = _offset! + 1;
        _offsetList.add(_offset);
        _isLoading = true;
      });
      await widget.onPaginate(_offset);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

    }else {
      if(_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if(widget.offset != null) {
      _offset = widget.offset;
      _offsetList = [];
      for(int index=1; index<=widget.offset!; index++) {
        _offsetList.add(index);
      }
    }

    return Column(children: [

      widget.reverse ? const SizedBox() : widget.itemView,

      (ResponsiveHelper.isDesktop(context) && (widget.totalSize == null || _offset! >= _pageCount() || _offsetList.contains(_offset!+1))) ? const SizedBox() : Center(child: Padding(
        padding: (_isLoading || ResponsiveHelper.isDesktop(context)) ? const EdgeInsets.all(Dimensions.paddingSizeSmall) : EdgeInsets.zero,
        child: _isLoading ? const CircularProgressIndicator() : (ResponsiveHelper.isDesktop(context) && widget.totalSize != null) ? InkWell(
          onTap: _paginate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              color: Theme.of(context).primaryColor,
            ),
            child: Text('view_more'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white)),
          ),
        ) : const SizedBox(),
      )),

      widget.reverse ? widget.itemView : const SizedBox(),

    ]);
  }
}
