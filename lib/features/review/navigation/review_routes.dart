import 'package:articlela/core/domain/entities/article_entity.dart';
import 'package:articlela/features/review/presentation/viewmodel/stage_review_viewmodel.dart';

class ReviewRoutes {
  ReviewRoutes._();

}

class StageReviewArguments {
  const StageReviewArguments({required this.items, this.initialState});

  final List<ArticleEntity> items;
  final StageReviewState? initialState;
}
