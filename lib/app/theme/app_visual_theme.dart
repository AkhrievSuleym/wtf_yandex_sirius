enum AppVisualTheme {
  meme,
  gothic;

  String get label {
    return switch (this) {
      meme => 'Мемный',
      gothic => 'Готический',
    };
  }

  String get description {
    return switch (this) {
      meme => 'Яркий, сочный, с наклейками',
      gothic => 'Тёмный, мрачный, с готическим шрифтом',
    };
  }

  String get emoji {
    return switch (this) {
      meme => '🎨',
      gothic => '🦇',
    };
  }
}
