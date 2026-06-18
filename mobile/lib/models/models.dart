// Modelos de dominio del cliente. Mapean las respuestas JSON de la API NestJS.

class Tournament {
  Tournament({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.startDate,
    required this.endDate,
    this.isPublished = false,
    this.categories = const [],
    this.venues = const [],
  });

  final String id;
  final String name;
  final String? logoUrl;
  final DateTime startDate;
  final DateTime endDate;
  final bool isPublished;
  final List<Category> categories;
  final List<Venue> venues;

  factory Tournament.fromJson(Map<String, dynamic> j) => Tournament(
        id: j['id'] as String,
        name: j['name'] as String,
        logoUrl: j['logoUrl'] as String?,
        startDate: DateTime.parse(j['startDate'] as String),
        endDate: DateTime.parse(j['endDate'] as String),
        isPublished: (j['isPublished'] as bool?) ?? false,
        categories: ((j['categories'] as List?) ?? [])
            .map((c) => Category.fromJson(c as Map<String, dynamic>))
            .toList(),
        venues: ((j['venues'] as List?) ?? [])
            .map((v) => Venue.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

class Venue {
  Venue({required this.id, required this.name, this.courts = const []});
  final String id;
  final String name;
  final List<Court> courts;

  factory Venue.fromJson(Map<String, dynamic> j) => Venue(
        id: j['id'] as String,
        name: j['name'] as String,
        courts: ((j['courts'] as List?) ?? [])
            .map((c) => Court.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class Court {
  Court({required this.id, required this.name});
  final String id;
  final String name;

  factory Court.fromJson(Map<String, dynamic> j) =>
      Court(id: j['id'] as String, name: j['name'] as String);
}

class Category {
  Category({
    required this.id,
    required this.name,
    required this.gender,
    required this.format,
    this.bestOf = 5,
  });

  final String id;
  final String name;
  final String gender; // MALE | FEMALE
  final String format;
  final int bestOf; // 3 = mejor de 3 ; 5 = mejor de 5

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        gender: j['gender'] as String,
        format: j['format'] as String,
        bestOf: (j['bestOf'] as int?) ?? 5,
      );

  String get genderLabel => gender == 'MALE' ? 'Masculino' : 'Femenino';
  String get bestOfLabel => bestOf == 3 ? 'Mejor de 3' : 'Mejor de 5';
}

class TeamRef {
  TeamRef({required this.id, required this.name, this.playerCount = 0});
  final String id;
  final String name;
  final int playerCount;

  factory TeamRef.fromJson(Map<String, dynamic> j) => TeamRef(
        id: j['id'] as String,
        name: j['name'] as String,
        playerCount: (j['_count']?['players'] as int?) ?? 0,
      );
}

class RefereeRef {
  RefereeRef({required this.id, required this.name, this.license, this.assignmentCount = 0});
  final String id;
  final String name;
  final String? license;
  final int assignmentCount;

  factory RefereeRef.fromJson(Map<String, dynamic> j) => RefereeRef(
        id: j['id'] as String,
        name: (j['user']?['fullName'] as String?) ?? (j['user']?['email'] as String?) ?? 'Árbitro',
        license: j['license'] as String?,
        assignmentCount: (j['_count']?['assignments'] as int?) ?? 0,
      );
}

class MatchSet {
  MatchSet({required this.setNumber, required this.homePoints, required this.awayPoints, required this.isFinished});
  final int setNumber;
  final int homePoints;
  final int awayPoints;
  final bool isFinished;

  factory MatchSet.fromJson(Map<String, dynamic> j) => MatchSet(
        setNumber: j['setNumber'] as int,
        homePoints: j['homePoints'] as int,
        awayPoints: j['awayPoints'] as int,
        isFinished: (j['isFinished'] as bool?) ?? false,
      );
}

class CourtInfo {
  CourtInfo({required this.name, this.venueName});
  final String name;
  final String? venueName;

  factory CourtInfo.fromJson(Map<String, dynamic> j) => CourtInfo(
        name: j['name'] as String,
        venueName: j['venue']?['name'] as String?,
      );

  /// "Sede · Cancha" o solo la cancha si no hay sede.
  String get label => venueName != null ? '$venueName · $name' : name;
}

class Match {
  Match({
    required this.id,
    this.homeTeam,
    this.awayTeam,
    this.scheduledAt,
    required this.status,
    required this.homeSetsWon,
    required this.awaySetsWon,
    this.court,
    this.sets = const [],
  });

  final String id;
  final TeamRef? homeTeam;
  final TeamRef? awayTeam;
  final DateTime? scheduledAt;
  final String status; // SCHEDULED | LIVE | FINISHED | SUSPENDED
  final int homeSetsWon;
  final int awaySetsWon;
  final CourtInfo? court;
  final List<MatchSet> sets;

  factory Match.fromJson(Map<String, dynamic> j) => Match(
        id: j['id'] as String,
        homeTeam: j['homeTeam'] != null ? TeamRef.fromJson(j['homeTeam']) : null,
        awayTeam: j['awayTeam'] != null ? TeamRef.fromJson(j['awayTeam']) : null,
        scheduledAt: j['scheduledAt'] != null ? DateTime.parse(j['scheduledAt']) : null,
        status: j['status'] as String,
        homeSetsWon: (j['homeSetsWon'] as int?) ?? 0,
        awaySetsWon: (j['awaySetsWon'] as int?) ?? 0,
        court: j['court'] != null ? CourtInfo.fromJson(j['court'] as Map<String, dynamic>) : null,
        sets: ((j['sets'] as List?) ?? [])
            .map((s) => MatchSet.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  bool get isLive => status == 'LIVE';
  bool get isFinished => status == 'FINISHED';
}

class Standing {
  Standing({
    required this.teamName,
    required this.played,
    required this.won,
    required this.lost,
    required this.points,
    required this.setsFor,
    required this.setsAgainst,
    required this.rank,
  });

  final String teamName;
  final int played, won, lost, points, setsFor, setsAgainst;
  final int? rank;

  factory Standing.fromJson(Map<String, dynamic> j) => Standing(
        teamName: (j['team']?['name'] as String?) ?? '—',
        played: (j['played'] as int?) ?? 0,
        won: (j['won'] as int?) ?? 0,
        lost: (j['lost'] as int?) ?? 0,
        points: (j['points'] as int?) ?? 0,
        setsFor: (j['setsFor'] as int?) ?? 0,
        setsAgainst: (j['setsAgainst'] as int?) ?? 0,
        rank: j['rank'] as int?,
      );

  int get setDiff => setsFor - setsAgainst;
}
