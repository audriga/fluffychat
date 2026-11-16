This fork explores using structured data ([SML](https://datatracker.ietf.org/group/sml/about/)) in matrix events.

* It can display sml events seen in room feed (both [variants](#variants))
* It can send sml events ([custom event type](#custom-event-type))

Related repositories are
* [jsonld2cards-flutter](https://github.com/audriga/jsonld2cards-flutter/tree/master) rendering library for structured data
* Our fork of [matrix-dart-sdk](https://github.com/audriga/matrix-dart-sdk/tree/enable-sml) to support custom message/ event types

# Variants
We internally discussed multiple variants of structured data in matrix messages/ events. Two of these we implemented here

## Custom Event Type

This is built upon the extensible events proposal ([MSC1767](https://github.com/matrix-org/matrix-spec-proposals/pull/1767))

We use a custom event-tpe of `org.sml`, respecitvely `org.matrix.msc9999.sml` (MSC9999 as a placeholder, since we have not created an MSC yet)
Here, the structured data is in the property `org.sml` or `org.matrix.msc9999.sml`, and the fallback text is in `org.matrix.msc1767.text`.

## Custom Message Type 

This approach uses an event of type `m.room.message`, with a custom message type of `m.sml`.

The structured data is contained in `formatted_body`, and the format is set to `json-ld`. 

We used this approach since the fallback text always showed up on unmodified clients.
However, we will likely remove this approach since it is somewhat "hacky".