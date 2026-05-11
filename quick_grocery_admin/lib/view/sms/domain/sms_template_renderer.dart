/// Replaces `{{token}}` placeholders with [vars] values (Blinkit-style copy).
String renderSmsTemplate(String template, Map<String, String> vars) {
  var out = template;
  vars.forEach((key, value) {
    out = out.replaceAll('{{$key}}', value);
  });
  return out;
}
