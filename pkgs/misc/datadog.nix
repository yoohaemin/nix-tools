{ stdenv, pkgs }:

let

  python-env = pkgs.python.withPackages ( pkgs: [ pkgs.datadog ]);

  datadog-push-event-script = pkgs.writeText "datadog-push-event" ''
    import argparse, datadog

    parser = argparse.ArgumentParser(prog='datadog-push-event')

    parser.add_argument('--api-key'         , required=True, help='Datadog API Key',         type=str)
    parser.add_argument('--app-key'         , required=True, help='Datadog APP Key',         type=str)
    parser.add_argument('--title'           , required=True, help='The title of the event',  type=str)
    parser.add_argument('--text'            , required=True, help='The body of the event',   type=str)

    parser.add_argument('--priority'        , help='The priority of the event',              type=str, choices=['normal', 'low'], default='normal')
    parser.add_argument('--alert-type'      , help='The type of the event alert',            type=str, choices=['error', 'warning', 'info', 'success'], default='info')
    parser.add_argument('--source-type-name', help='The type of the event',                  type=str)
    parser.add_argument('--aggregation-key' , help='Arbitrary string for aggregation',       type=str)
    parser.add_argument('--tags'            , help='A space-separated list of tags',         type=str)
    parser.add_argument('--host'            , help='Host name to associate with the event',  type=str)

    args = parser.parse_args()

    options = {
      'api_key': args.api_key,
      'app_key': args.app_key,
    }

    datadog.initialize(**options)

    if hasattr(args, 'tags'):
        tags = args.tags.split(' ')
    else:
        tags = []

    datadog.api.Event.create(
      title = args.title,
      text = args.text,
      tags = tags,
      priority = args.priority,
      alert_type = args.alert_type,
      aggregation_key = getattr(args, 'aggregation_key', None),
      source_type_name = getattr(args, 'source_type_name', None),
      host = getattr(args, 'host', None),
    )

  '';

  datadog-push-metric-script = pkgs.writeText "datadog-push-metric" ''
    import argparse, time, datadog

    parser = argparse.ArgumentParser(prog='datadog-push-metric')

    parser.add_argument('--api-key'         , required=True, help='Datadog API Key',         type=str)
    parser.add_argument('--app-key'         , required=True, help='Datadog APP Key',         type=str)
    parser.add_argument('--metric'          , required=True, help='Name of the time series', type=str)
    parser.add_argument('--value'           , required=True, help='The value of the metric', type=float)

    parser.add_argument('--type'            , help='The type of the metric',                 type=str, choices=['gauge', 'rate', 'count'], default='gauge')
    parser.add_argument('--tags'            , help='A space-separated list of tags',         type=str)
    parser.add_argument('--host'            , help='Host name to associate with the metric', type=str)

    args = parser.parse_args()

    options = {
      'api_key': args.api_key,
      'app_key': args.app_key,
    }

    datadog.initialize(**options)

    if hasattr(args, 'tags'):
        tags = args.tags.split(' ')
    else:
        tags = []

    datadog.api.Metric.send(
      metric = args.metric,
      type = args.type,
      points = (time.time(), args.value),
      host = getattr(args, 'host', None),
      tags = tags,
    )
  '';

  datadog-push-event = pkgs.writeShellScriptBin "datadog-push-event" ''
    ${python-env}/bin/python ${datadog-push-event-script} "$@"
  '';

  datadog-push-metric = pkgs.writeShellScriptBin "datadog-push-metric" ''
    ${python-env}/bin/python ${datadog-push-metric-script} "$@"
  '';

in pkgs.symlinkJoin {
  name = "datadog-scripts";
  paths = [
    datadog-push-event
    datadog-push-metric
  ];
}
