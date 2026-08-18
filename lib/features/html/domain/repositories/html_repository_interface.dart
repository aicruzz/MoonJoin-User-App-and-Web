import 'package:moonjoin/interfaces/repository_interface.dart';
import 'package:moonjoin/util/html_type.dart';

abstract class HtmlRepositoryInterface extends RepositoryInterface {
  Future<dynamic> getHtmlText(HtmlType htmlType);
}