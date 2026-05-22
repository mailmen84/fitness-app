"""Seed ~200 generic Polish food entries with macros per 100g.

These are basics that are commonly missing or noisy in Open Food Facts because
OFF focuses on packaged products with barcodes (Snickers, Nutella, etc).
The list below covers raw and cooked staples that everyone tracks.

Sources for macro values: USDA FoodData Central (https://fdc.nal.usda.gov/)
and Polish IZZ tables. Values per 100g, edible portion, raw unless noted.

Usage:
    python -m scripts.seed_polish_basics
"""

from __future__ import annotations

import os
import sys
import uuid
from decimal import Decimal

import psycopg


# Each tuple: (name_pl, calories, protein, carbs, fat)
# All values per 100g of edible portion.
SEED: list[tuple[str, float, float, float, float]] = [
    # --- Warzywa swieze ---
    ('Ziemniak surowy', 77, 2.0, 17.5, 0.1),
    ('Ziemniak gotowany', 87, 1.9, 20.1, 0.1),
    ('Ziemniak pieczony', 93, 2.5, 21.1, 0.1),
    ('Pomidor', 18, 0.9, 3.9, 0.2),
    ('Pomidor koktajlowy', 18, 0.9, 3.9, 0.2),
    ('Ogorek', 15, 0.7, 3.6, 0.1),
    ('Ogorek kiszony', 11, 0.5, 2.3, 0.2),
    ('Marchew surowa', 41, 0.9, 9.6, 0.2),
    ('Marchew gotowana', 35, 0.8, 8.2, 0.2),
    ('Cebula', 40, 1.1, 9.3, 0.1),
    ('Czosnek', 149, 6.4, 33.1, 0.5),
    ('Papryka czerwona', 31, 1.0, 6.0, 0.3),
    ('Papryka zielona', 20, 0.9, 4.6, 0.2),
    ('Papryka zolta', 27, 1.0, 6.3, 0.2),
    ('Saleta zielona', 15, 1.4, 2.9, 0.2),
    ('Saleta lodowa', 14, 0.9, 3.0, 0.1),
    ('Roszponka', 21, 2.0, 3.6, 0.4),
    ('Rukola', 25, 2.6, 3.7, 0.7),
    ('Szpinak surowy', 23, 2.9, 3.6, 0.4),
    ('Szpinak gotowany', 23, 3.0, 3.8, 0.3),
    ('Brokul surowy', 34, 2.8, 6.6, 0.4),
    ('Brokul gotowany', 35, 2.4, 7.2, 0.4),
    ('Kalafior surowy', 25, 1.9, 5.0, 0.3),
    ('Kalafior gotowany', 23, 1.8, 4.1, 0.5),
    ('Brukselka', 43, 3.4, 9.0, 0.3),
    ('Kapusta biala', 25, 1.3, 5.8, 0.1),
    ('Kapusta czerwona', 31, 1.4, 7.4, 0.2),
    ('Kapusta kiszona', 19, 0.9, 4.3, 0.1),
    ('Cukinia', 17, 1.2, 3.1, 0.3),
    ('Bakazan', 25, 1.0, 5.9, 0.2),
    ('Dynia', 26, 1.0, 6.5, 0.1),
    ('Burak surowy', 43, 1.6, 9.6, 0.2),
    ('Burak gotowany', 44, 1.7, 10.0, 0.2),
    ('Seler korzeniowy', 42, 1.5, 9.2, 0.3),
    ('Pieczarki surowe', 22, 3.1, 3.3, 0.3),
    ('Pieczarki smazone', 70, 4.5, 3.5, 4.2),
    ('Boczniaki', 33, 3.3, 6.1, 0.4),
    ('Por', 61, 1.5, 14.2, 0.3),
    ('Rzodkiewka', 16, 0.7, 3.4, 0.1),
    ('Fasolka szparagowa', 31, 1.8, 7.0, 0.2),
    ('Groszek zielony', 81, 5.4, 14.5, 0.4),
    ('Kukurydza w puszce', 86, 3.3, 19.0, 1.4),

    # --- Owoce ---
    ('Jablko', 52, 0.3, 13.8, 0.2),
    ('Gruszka', 57, 0.4, 15.2, 0.1),
    ('Banan', 89, 1.1, 22.8, 0.3),
    ('Pomarancza', 47, 0.9, 11.8, 0.1),
    ('Mandarynka', 53, 0.8, 13.3, 0.3),
    ('Cytryna', 29, 1.1, 9.3, 0.3),
    ('Grejpfrut', 42, 0.8, 10.7, 0.1),
    ('Kiwi', 61, 1.1, 14.7, 0.5),
    ('Truskawki', 32, 0.7, 7.7, 0.3),
    ('Maliny', 52, 1.2, 11.9, 0.7),
    ('Borowki', 57, 0.7, 14.5, 0.3),
    ('Czarne porzeczki', 63, 1.4, 15.4, 0.4),
    ('Wisnie', 50, 1.0, 12.2, 0.3),
    ('Czeresnie', 63, 1.1, 16.0, 0.2),
    ('Sliwki', 46, 0.7, 11.4, 0.3),
    ('Brzoskwinia', 39, 0.9, 9.5, 0.3),
    ('Morele', 48, 1.4, 11.1, 0.4),
    ('Ananas', 50, 0.5, 13.1, 0.1),
    ('Mango', 60, 0.8, 15.0, 0.4),
    ('Awokado', 160, 2.0, 8.5, 14.7),
    ('Winogrona', 69, 0.7, 18.1, 0.2),
    ('Arbuz', 30, 0.6, 7.6, 0.2),
    ('Melon', 34, 0.8, 8.2, 0.2),
    ('Granat', 83, 1.7, 18.7, 1.2),
    ('Daktyle suszone', 282, 2.5, 75.0, 0.4),
    ('Rodzynki', 299, 3.1, 79.2, 0.5),
    ('Suszone morele', 241, 3.4, 62.6, 0.5),
    ('Suszone sliwki', 240, 2.2, 63.9, 0.4),

    # --- Miesa surowe ---
    ('Piers z kurczaka surowa', 120, 22.5, 0.0, 2.6),
    ('Piers z kurczaka grilowana', 165, 31.0, 0.0, 3.6),
    ('Udo z kurczaka surowe', 172, 18.6, 0.0, 10.9),
    ('Skrzydelka z kurczaka', 203, 18.3, 0.0, 14.1),
    ('Piers z indyka surowa', 110, 24.6, 0.0, 1.0),
    ('Polowka indyka pieczona', 170, 29.0, 0.0, 5.0),
    ('Wieprzowina schab surowy', 143, 21.5, 0.0, 6.2),
    ('Wieprzowina karczek surowy', 215, 17.6, 0.0, 16.0),
    ('Wieprzowina szynka', 145, 21.0, 0.5, 6.5),
    ('Boczek surowy', 540, 12.0, 1.3, 53.0),
    ('Boczek smazony', 533, 36.0, 1.4, 41.8),
    ('Wolowina rostbef surowy', 158, 21.4, 0.0, 7.7),
    ('Wolowina karkowka', 235, 17.0, 0.0, 18.0),
    ('Mielone wolowe', 250, 17.2, 0.0, 20.0),
    ('Mielone wieprzowe', 263, 16.9, 0.0, 21.8),
    ('Cielecina', 144, 19.0, 0.0, 7.5),
    ('Jagniecina', 294, 16.6, 0.0, 25.6),

    # --- Wedliny i przetwory miesne ---
    ('Szynka konserwowa', 110, 18.0, 1.0, 4.0),
    ('Szynka wiejska', 145, 19.0, 0.5, 7.0),
    ('Kielbasa zwyczajna', 305, 13.0, 1.5, 27.5),
    ('Kabanos', 446, 25.0, 0.5, 38.0),
    ('Parowki', 235, 11.0, 4.0, 20.0),
    ('Salami', 410, 22.0, 1.5, 34.0),
    ('Mortadela', 311, 14.0, 1.0, 27.0),
    ('Polędwica drobiowa', 130, 22.0, 0.5, 4.0),

    # --- Ryby ---
    ('Losos surowy', 208, 20.0, 0.0, 13.0),
    ('Losos pieczony', 206, 22.0, 0.0, 12.4),
    ('Losos wedzony', 117, 18.3, 0.0, 4.3),
    ('Dorsz surowy', 82, 18.0, 0.0, 0.7),
    ('Dorsz pieczony', 105, 23.0, 0.0, 0.9),
    ('Tunczyk surowy', 132, 28.0, 0.0, 1.0),
    ('Tunczyk w oleju z puszki', 198, 26.0, 0.0, 10.0),
    ('Tunczyk w wlasnym sosie', 116, 26.0, 0.0, 1.0),
    ('Sledz w oleju', 250, 17.0, 1.5, 19.0),
    ('Makrela wedzona', 220, 19.0, 0.0, 16.0),
    ('Pstrag surowy', 119, 20.0, 0.0, 3.5),
    ('Krewetki gotowane', 99, 24.0, 0.2, 0.3),
    ('Mintaj', 81, 17.5, 0.0, 0.8),

    # --- Jajka i nabial ---
    ('Jajko kurze', 143, 12.6, 0.7, 9.5),
    ('Jajko na twardo', 155, 12.6, 1.1, 10.6),
    ('Jajko sadzone', 196, 13.6, 0.8, 14.8),
    ('Bialko jaja', 52, 11.0, 0.7, 0.2),
    ('Zoltko jaja', 322, 16.0, 3.6, 27.0),
    ('Mleko 0%', 35, 3.4, 5.0, 0.2),
    ('Mleko 1,5%', 47, 3.4, 4.9, 1.5),
    ('Mleko 2%', 50, 3.4, 4.8, 2.0),
    ('Mleko 3,2%', 64, 3.3, 4.7, 3.2),
    ('Mleko sojowe', 33, 3.3, 1.8, 1.7),
    ('Mleko owsiane', 43, 1.0, 6.6, 1.5),
    ('Mleko migdalowe', 13, 0.4, 0.6, 1.1),
    ('Jogurt naturalny 2%', 61, 3.5, 4.7, 3.3),
    ('Jogurt naturalny 0%', 56, 5.7, 7.0, 0.2),
    ('Jogurt grecki 2%', 95, 6.7, 4.0, 5.0),
    ('Jogurt grecki 10%', 133, 6.0, 4.0, 10.0),
    ('Twarog chudy', 99, 19.8, 3.5, 0.5),
    ('Twarog polttusty', 133, 17.0, 3.0, 5.5),
    ('Twarog tlusty', 175, 16.0, 3.0, 11.0),
    ('Serek wiejski', 100, 12.0, 3.0, 4.5),
    ('Mascarpone', 412, 4.8, 4.8, 42.0),
    ('Ser zolty Gouda', 356, 25.0, 2.2, 27.4),
    ('Ser zolty Edam', 357, 25.0, 1.4, 28.0),
    ('Ser zolty Cheddar', 403, 25.0, 1.3, 33.0),
    ('Mozzarella', 280, 28.0, 3.1, 17.0),
    ('Mozzarella light', 200, 30.0, 2.0, 8.0),
    ('Parmezan', 392, 35.8, 4.0, 25.8),
    ('Feta', 264, 14.2, 4.1, 21.3),
    ('Pleśniowy ser', 353, 21.4, 2.3, 28.7),
    ('Camembert', 300, 19.8, 0.5, 24.3),
    ('Smietana 12%', 132, 2.7, 4.0, 12.0),
    ('Smietana 18%', 186, 2.5, 3.9, 18.0),
    ('Smietana 30%', 290, 2.4, 3.0, 30.0),
    ('Maslo', 717, 0.9, 0.1, 81.1),
    ('Margaryna', 717, 0.2, 0.7, 80.0),

    # --- Zboza, makarony, ryze ---
    ('Ryz bialy surowy', 365, 7.1, 80.0, 0.7),
    ('Ryz bialy gotowany', 130, 2.7, 28.0, 0.3),
    ('Ryz brazowy surowy', 370, 7.9, 77.2, 2.9),
    ('Ryz brazowy gotowany', 123, 2.7, 25.6, 1.0),
    ('Ryz basmati gotowany', 121, 3.0, 25.0, 0.4),
    ('Ryz jasminowy gotowany', 129, 2.7, 28.0, 0.2),
    ('Kasza gryczana surowa', 343, 13.2, 71.5, 3.4),
    ('Kasza gryczana gotowana', 92, 3.4, 19.9, 0.6),
    ('Kasza jaglana surowa', 378, 11.0, 73.0, 4.2),
    ('Kasza jaglana gotowana', 119, 3.5, 23.7, 1.0),
    ('Kasza jeczmienna', 354, 9.9, 73.5, 1.2),
    ('Kasza manna', 360, 13.0, 73.0, 1.0),
    ('Kuskus suchy', 376, 12.8, 77.4, 0.6),
    ('Kuskus gotowany', 112, 3.8, 23.2, 0.2),
    ('Quinoa surowa', 368, 14.1, 64.2, 6.1),
    ('Quinoa gotowana', 120, 4.4, 21.3, 1.9),
    ('Makaron pszenny suchy', 371, 13.0, 75.0, 1.5),
    ('Makaron pszenny gotowany', 158, 5.8, 31.0, 0.9),
    ('Makaron razowy suchy', 348, 14.6, 70.0, 2.8),
    ('Makaron razowy gotowany', 124, 5.3, 26.5, 0.5),
    ('Makaron ryzowy gotowany', 109, 2.0, 24.0, 0.2),
    ('Platki owsiane', 379, 13.2, 67.7, 6.5),
    ('Platki kukurydziane', 357, 7.5, 84.0, 0.4),
    ('Musli klasyczne', 380, 10.0, 62.0, 8.0),
    ('Chleb pszenny', 247, 8.5, 49.0, 3.0),
    ('Chleb zytni razowy', 218, 8.2, 41.0, 2.4),
    ('Chleb pelnoziarnisty', 247, 13.0, 41.0, 3.4),
    ('Buleczka', 296, 9.0, 53.5, 5.5),
    ('Bagietka', 269, 8.9, 51.9, 2.7),
    ('Tortilla pszenna', 304, 8.7, 55.0, 7.0),

    # --- Roslin straczkowe ---
    ('Soczewica suche', 353, 25.8, 60.0, 1.1),
    ('Soczewica gotowana', 116, 9.0, 20.0, 0.4),
    ('Ciecierzyca sucha', 364, 19.0, 61.0, 6.0),
    ('Ciecierzyca gotowana', 164, 8.9, 27.4, 2.6),
    ('Fasola biala sucha', 333, 23.0, 60.0, 1.0),
    ('Fasola biala gotowana', 139, 9.7, 25.1, 0.5),
    ('Fasola czerwona sucha', 337, 22.5, 61.0, 1.1),
    ('Fasola czerwona gotowana', 127, 8.7, 22.8, 0.5),
    ('Groch suchy', 341, 25.0, 60.4, 1.2),
    ('Groch gotowany', 81, 5.4, 14.5, 0.4),

    # --- Tluszcze, oleje, orzechy ---
    ('Oliwa z oliwek', 884, 0.0, 0.0, 100.0),
    ('Olej rzepakowy', 884, 0.0, 0.0, 100.0),
    ('Olej slonecznikowy', 884, 0.0, 0.0, 100.0),
    ('Olej kokosowy', 862, 0.0, 0.0, 100.0),
    ('Olej lniany', 884, 0.0, 0.0, 100.0),
    ('Migdaly', 579, 21.2, 21.6, 49.9),
    ('Orzechy wloskie', 654, 15.2, 13.7, 65.2),
    ('Orzechy laskowe', 628, 15.0, 16.7, 60.8),
    ('Orzechy nerkowca', 553, 18.2, 30.2, 43.9),
    ('Orzechy pistacjowe', 562, 20.2, 27.2, 45.3),
    ('Orzeszki ziemne', 567, 25.8, 16.1, 49.2),
    ('Maslo orzechowe', 588, 25.0, 20.0, 50.0),
    ('Pestki dyni', 559, 30.2, 10.7, 49.0),
    ('Pestki slonecznika', 584, 20.8, 20.0, 51.5),
    ('Sezam', 573, 17.7, 23.4, 49.7),
    ('Siemie lniane', 534, 18.3, 28.9, 42.2),
    ('Chia nasiona', 486, 16.5, 42.1, 30.7),

    # --- Slodycze i wypieki ---
    ('Cukier bialy', 387, 0.0, 99.8, 0.0),
    ('Cukier trzcinowy', 380, 0.0, 99.0, 0.0),
    ('Miod', 304, 0.3, 82.4, 0.0),
    ('Syrop klonowy', 260, 0.0, 67.0, 0.1),
    ('Czekolada gorzka 70%', 598, 7.8, 45.9, 42.6),
    ('Czekolada mleczna', 535, 7.6, 59.4, 29.7),
    ('Nutella', 539, 6.3, 57.5, 30.9),
    ('Lody waniliowe', 207, 3.5, 23.6, 11.0),

    # --- Napoje ---
    ('Woda mineralna', 0, 0.0, 0.0, 0.0),
    ('Coca-Cola', 42, 0.0, 10.6, 0.0),
    ('Coca-Cola Zero', 0, 0.0, 0.0, 0.0),
    ('Sok pomaranczowy 100%', 45, 0.7, 10.4, 0.2),
    ('Sok jablkowy 100%', 46, 0.1, 11.3, 0.1),
    ('Piwo jasne 5%', 43, 0.5, 3.6, 0.0),
    ('Wino bialwe wytrawne', 82, 0.1, 2.6, 0.0),
    ('Wino czerwone wytrawne', 85, 0.1, 2.6, 0.0),
    ('Wodka 40%', 231, 0.0, 0.0, 0.0),
    ('Kawa czarna bez cukru', 2, 0.1, 0.0, 0.0),
    ('Herbata bez cukru', 1, 0.0, 0.2, 0.0),

    # --- Sosy i przyprawy (per 100g, uwaga: porcje sa male) ---
    ('Ketchup', 112, 1.2, 26.8, 0.4),
    ('Majonez', 680, 1.1, 2.6, 75.0),
    ('Musztarda', 66, 4.4, 5.8, 4.0),
    ('Sos sojowy', 53, 8.1, 4.9, 0.6),
    ('Sos pomidorowy', 32, 1.5, 7.0, 0.2),
    ('Pesto bazyliowe', 480, 5.5, 5.0, 49.0),
    ('Sol', 0, 0.0, 0.0, 0.0),

    # --- Inne ---
    ('Tofu naturalne', 76, 8.1, 1.9, 4.8),
    ('Hummus', 166, 7.9, 14.3, 9.6),
    ('Pierogi ruskie gotowane', 200, 6.5, 32.0, 5.0),
    ('Pierogi z miesem gotowane', 235, 9.5, 30.0, 8.5),
    ('Naleśnik z dżemem', 184, 4.5, 30.0, 5.0),
    ('Placek ziemniaczany', 268, 4.5, 28.0, 16.0),
    ('Bigos', 122, 6.5, 8.5, 7.0),
    ('Goloabki w sosie pomidorowym', 130, 7.0, 12.0, 6.0),
    ('Schabowy panierowany', 286, 22.0, 12.0, 17.0),
    ('Frytki z fast food', 312, 3.4, 41.0, 15.0),
    ('Pizza Margherita', 266, 11.0, 33.0, 10.0),
    ('Hamburger', 295, 17.0, 25.0, 14.0),
]


def main() -> int:
    url = os.environ.get('BACKEND_DATABASE_URL') or os.environ.get('DATABASE_URL')
    if not url:
        print('ERROR: BACKEND_DATABASE_URL not set', file=sys.stderr)
        return 2
    dsn = url.replace('+asyncpg', '').replace('postgresql+psycopg', 'postgresql')

    print(f'Seeding {len(SEED)} Polish basics...', flush=True)

    conn = psycopg.connect(dsn, autocommit=False)
    try:
        with conn.cursor() as cur:
            # Check which names already exist as PL seed (skip duplicates).
            cur.execute(
                "SELECT name FROM foods WHERE source = 'seed_pl'"
            )
            existing = {row[0] for row in cur.fetchall()}
            print(f'Already in DB as seed_pl: {len(existing)}', flush=True)

            inserted = 0
            for name, kcal, p, c, f in SEED:
                if name in existing:
                    continue
                food_id = uuid.uuid4()
                cur.execute(
                    """
                    INSERT INTO foods (
                        id, name, brand, barcode,
                        default_serving_amount, default_serving_unit,
                        source, is_verified
                    ) VALUES (%s, %s, NULL, NULL, %s, %s, %s, %s)
                    """,
                    (
                        food_id,
                        name,
                        Decimal('100.00'),
                        'g',
                        'seed_pl',
                        True,
                    ),
                )
                nutrient_rows = [
                    (uuid.uuid4(), food_id, 'calories', 'Calories', Decimal(str(kcal)), 'kcal', 1),
                    (uuid.uuid4(), food_id, 'protein', 'Protein', Decimal(str(p)), 'g', 2),
                    (uuid.uuid4(), food_id, 'carbs', 'Carbohydrates', Decimal(str(c)), 'g', 3),
                    (uuid.uuid4(), food_id, 'fat', 'Fat', Decimal(str(f)), 'g', 4),
                ]
                cur.executemany(
                    """
                    INSERT INTO food_nutrients (
                        id, food_id, nutrient_code, nutrient_name,
                        amount, unit, display_order
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    nutrient_rows,
                )
                inserted += 1

        conn.commit()
        print(f'DONE. Inserted {inserted} new entries.', flush=True)
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return 0


if __name__ == '__main__':
    sys.exit(main())
