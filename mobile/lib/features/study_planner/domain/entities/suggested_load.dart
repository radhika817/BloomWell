/// The suggested academic study load for a planned day.
enum SuggestedLoad {
  light('light'),
  normal('normal'),
  focus('focus');

  const SuggestedLoad(this.apiValue);
  final String apiValue;

  static SuggestedLoad fromString(String value) {
    switch (value.toLowerCase()) {
      case 'light':
        return SuggestedLoad.light;
      case 'focus':
        return SuggestedLoad.focus;
      case 'normal':
      default:
        return SuggestedLoad.normal;
    }
  }
}
