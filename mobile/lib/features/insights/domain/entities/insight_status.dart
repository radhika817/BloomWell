/// Status indicating whether sufficient data exists to formulate observations.
enum InsightStatus {
  sufficientData('sufficient_data'),
  notEnoughData('not_enough_data');

  const InsightStatus(this.apiValue);
  final String apiValue;

  static InsightStatus fromString(String value) {
    if (value.toLowerCase() == 'sufficient_data') {
      return InsightStatus.sufficientData;
    }
    return InsightStatus.notEnoughData;
  }
}
