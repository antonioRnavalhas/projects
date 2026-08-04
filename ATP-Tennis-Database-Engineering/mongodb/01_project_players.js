// Run in mongosh while connected to the database that contains `atpplayers`.
// The source field names mirror the historical project export; the output
// names match the public MySQL staging schema.

db.getCollection("atpplayers").aggregate(
  [
    {
      $project: {
        _id: 0,
        record_id: { $toString: "$_id" },
        player_name: "$PlayerName",
        birth_location: "$Born",
        height_cm: "$Height",
        hand: "$Hand",
        tournament: "$Tournament",
        tournament_category: {
          $ifNull: ["$TournamentCategory", "Other"]
        },
        event_location: "$Location",
        date_range: { $ifNull: ["$DateRange", "$Date"] },
        surface: "$Ground",
        prize_usd: "$Prize",
        round_name: "$GameRound",
        ranking: "$GameRank",
        opponent_name: { $ifNull: ["$Opponent", "$Oponent"] },
        result: "$WL"
      }
    },
    { $out: "atp_export" }
  ],
  { allowDiskUse: true }
);

// Example export command (run from a shell after reviewing source-data terms):
// mongoexport --db YOUR_DATABASE --collection atp_export --type=csv \
//   --fields record_id,player_name,birth_location,height_cm,hand,tournament,tournament_category,event_location,date_range,surface,prize_usd,round_name,ranking,opponent_name,result \
//   --out atp_export.csv
