/// Deterministic conversation ids. A thread is keyed to the deal or request
/// that opened it (no bare DMs — BRAIN §5), so its metadata can always be
/// derived from that id without a separate conversations table.
String convIdForDeal(String dealId) => 'conv_deal_$dealId';
String convIdForRequest(String requestId) => 'conv_req_$requestId';

/// Parse helpers.
String? dealIdFromConv(String conversationId) =>
    conversationId.startsWith('conv_deal_')
        ? conversationId.substring('conv_deal_'.length)
        : null;

String? requestIdFromConv(String conversationId) =>
    conversationId.startsWith('conv_req_')
        ? conversationId.substring('conv_req_'.length)
        : null;
