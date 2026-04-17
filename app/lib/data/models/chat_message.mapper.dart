// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'chat_message.dart';

class ChatMessageMapper extends ClassMapperBase<ChatMessage> {
  ChatMessageMapper._();

  static ChatMessageMapper? _instance;
  static ChatMessageMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChatMessageMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ChatMessage';

  static String _$id(ChatMessage v) => v.id;
  static const Field<ChatMessage, String> _f$id = Field('id', _$id);
  static String _$senderId(ChatMessage v) => v.senderId;
  static const Field<ChatMessage, String> _f$senderId =
      Field('senderId', _$senderId);
  static String _$senderName(ChatMessage v) => v.senderName;
  static const Field<ChatMessage, String> _f$senderName =
      Field('senderName', _$senderName);
  static String _$text(ChatMessage v) => v.text;
  static const Field<ChatMessage, String> _f$text = Field('text', _$text);
  static DateTime _$timestamp(ChatMessage v) => v.timestamp;
  static const Field<ChatMessage, DateTime> _f$timestamp =
      Field('timestamp', _$timestamp);
  static bool _$isAi(ChatMessage v) => v.isAi;
  static const Field<ChatMessage, bool> _f$isAi =
      Field('isAi', _$isAi, opt: true, def: false);

  @override
  final MappableFields<ChatMessage> fields = const {
    #id: _f$id,
    #senderId: _f$senderId,
    #senderName: _f$senderName,
    #text: _f$text,
    #timestamp: _f$timestamp,
    #isAi: _f$isAi,
  };

  static ChatMessage _instantiate(DecodingData data) {
    return ChatMessage(
        id: data.dec(_f$id),
        senderId: data.dec(_f$senderId),
        senderName: data.dec(_f$senderName),
        text: data.dec(_f$text),
        timestamp: data.dec(_f$timestamp),
        isAi: data.dec(_f$isAi));
  }

  @override
  final Function instantiate = _instantiate;

  static ChatMessage fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChatMessage>(map);
  }

  static ChatMessage fromJson(String json) {
    return ensureInitialized().decodeJson<ChatMessage>(json);
  }
}

mixin ChatMessageMappable {
  String toJson() {
    return ChatMessageMapper.ensureInitialized()
        .encodeJson<ChatMessage>(this as ChatMessage);
  }

  Map<String, dynamic> toMap() {
    return ChatMessageMapper.ensureInitialized()
        .encodeMap<ChatMessage>(this as ChatMessage);
  }

  ChatMessageCopyWith<ChatMessage, ChatMessage, ChatMessage> get copyWith =>
      _ChatMessageCopyWithImpl(this as ChatMessage, $identity, $identity);
  @override
  String toString() {
    return ChatMessageMapper.ensureInitialized()
        .stringifyValue(this as ChatMessage);
  }

  @override
  bool operator ==(Object other) {
    return ChatMessageMapper.ensureInitialized()
        .equalsValue(this as ChatMessage, other);
  }

  @override
  int get hashCode {
    return ChatMessageMapper.ensureInitialized().hashValue(this as ChatMessage);
  }
}

extension ChatMessageValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ChatMessage, $Out> {
  ChatMessageCopyWith<$R, ChatMessage, $Out> get $asChatMessage =>
      $base.as((v, t, t2) => _ChatMessageCopyWithImpl(v, t, t2));
}

abstract class ChatMessageCopyWith<$R, $In extends ChatMessage, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call(
      {String? id,
      String? senderId,
      String? senderName,
      String? text,
      DateTime? timestamp,
      bool? isAi});
  ChatMessageCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ChatMessageCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChatMessage, $Out>
    implements ChatMessageCopyWith<$R, ChatMessage, $Out> {
  _ChatMessageCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChatMessage> $mapper =
      ChatMessageMapper.ensureInitialized();
  @override
  $R call(
          {String? id,
          String? senderId,
          String? senderName,
          String? text,
          DateTime? timestamp,
          bool? isAi}) =>
      $apply(FieldCopyWithData({
        if (id != null) #id: id,
        if (senderId != null) #senderId: senderId,
        if (senderName != null) #senderName: senderName,
        if (text != null) #text: text,
        if (timestamp != null) #timestamp: timestamp,
        if (isAi != null) #isAi: isAi
      }));
  @override
  ChatMessage $make(CopyWithData data) => ChatMessage(
      id: data.get(#id, or: $value.id),
      senderId: data.get(#senderId, or: $value.senderId),
      senderName: data.get(#senderName, or: $value.senderName),
      text: data.get(#text, or: $value.text),
      timestamp: data.get(#timestamp, or: $value.timestamp),
      isAi: data.get(#isAi, or: $value.isAi));

  @override
  ChatMessageCopyWith<$R2, ChatMessage, $Out2> $chain<$R2, $Out2>(
          Then<$Out2, $R2> t) =>
      _ChatMessageCopyWithImpl($value, $cast, t);
}
