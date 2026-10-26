/// User decision status on a study plan item.
enum PlanItemStatus {
  suggested('suggested'),
  accepted('accepted'),
  edited('edited'),
  skipped('skipped');

  const PlanItemStatus(this.apiValue);
  final String apiValue;

  static PlanItemStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'accepted':
        return PlanItemStatus.accepted;
      case 'edited':
        return PlanItemStatus.edited;
      case 'skipped':
        return PlanItemStatus.skipped;
      case 'suggested':
      default:
        return PlanItemStatus.suggested;
    }
  }
}
