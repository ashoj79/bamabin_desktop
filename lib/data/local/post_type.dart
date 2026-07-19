enum PostType {
  movie('movies', 'فیلم'),
  series('series', 'سریال'),
  anime('anime', 'انیمه'),
  animation('animations', 'انیمیشن');

  final String value;
  final String title;

  const PostType(this.value, this.title);
}