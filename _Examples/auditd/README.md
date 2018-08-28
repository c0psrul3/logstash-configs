## Logstash-auditlog

This is intended to provide patterns for parsing of auditd entries. This
is intended to extend the patterns [available elsewhere](https://www.omniref.com/github/ministryofjustice/logstash-formula/1.5.3/files/logstash/templates/logstash/patterns/auditd-pattern).
The format of auditd logs is rather complex and not well suited to regex-based
parsers like grok, but we can make some progress. The `kv` filter can also be
used for pure `audit.log` entries, as they are in a key/value format already.

### Patterns
The pattern-files are found in the `patterns/` directory.

### Examples
Several examples of inputs and filters can be found in the `examples/` directory.
