import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../services/series_info_service.dart';

class SeriesInfoBuilder extends StatefulWidget {
  final int seriesId;
  final Stream<SeriesInfoState> Function(int seriesId)? watch;
  final Duration patience;
  final Widget Function(BuildContext context, SeriesInfoState state) builder;

  const SeriesInfoBuilder({
    required this.seriesId,
    required this.builder,
    this.watch,
    this.patience = const Duration(seconds: 30),
    super.key,
  });

  @override
  State<SeriesInfoBuilder> createState() => _SeriesInfoBuilderState();
}

class _SeriesInfoBuilderState extends State<SeriesInfoBuilder> {
  SeriesInfoState _state = loadingSeriesInfo;
  StreamSubscription<SeriesInfoState>? _subscription;
  Timer? _giveUp;

  @override
  void initState() {
    super.initState();
    final watch = widget.watch ?? SeriesInfoService().watch;
    _subscription = watch(widget.seriesId).listen(_update);
    _giveUp = Timer(widget.patience, () {
      if (_state.status == SeriesInfoStatus.loading) {
        _update(unavailableSeriesInfo);
      }
    });
  }

  void _update(SeriesInfoState state) {
    if (state.status != SeriesInfoStatus.loading) _giveUp?.cancel();
    if (mounted) setState(() => _state = state);
  }

  @override
  void dispose() {
    _giveUp?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _state);
}
