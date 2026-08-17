

```markdown
# Challenge 03: Logic Puzzle Solution

## Assumptions

- The five houses are numbered **1 to 5 from left to right**.
- “Next to” means **immediately adjacent**.
- “The green house is immediately to the left of the white house” means if the green house is house `i`, the white house is house `i + 1`.
- Each color, nationality, drink, pet, and cigarette brand appears exactly once.

---

## Deduction Steps

### 1. Place the Norwegian and the center drink

From clue 9:

- House 1: Norwegian

From clue 8:

- House 3: drinks milk

So far:

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Nationality | Norwegian |  |  |  |  |
| Drink |  |  | milk |  |  |

---

### 2. Use the Norwegian’s neighbor clue

Clue 14 says the Norwegian lives next to the blue house.

Since the Norwegian is in house 1, the only neighboring house is house 2.

Therefore:

- House 2: blue

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color |  | blue |  |  |  |
| Nationality | Norwegian |  |  |  |  |
| Drink |  |  | milk |  |  |

---

### 3. Place the green and white houses

Clue 4 says green is immediately left of white.

Possible green/white pairs:

- Houses 1 and 2
- Houses 2 and 3
- Houses 3 and 4
- Houses 4 and 5

But house 2 is blue, so the pair cannot be 1–2 or 2–3.

Clue 5 says the green house drinks coffee. House 3 drinks milk, so house 3 cannot be green. Therefore the pair cannot be 3–4.

Thus:

- House 4: green
- House 5: white
- House 4: drinks coffee

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color |  | blue |  | green | white |
| Nationality | Norwegian |  |  |  |  |
| Drink |  |  | milk | coffee |  |

---

### 4. Determine the remaining colors

The remaining colors are red and yellow.

Clue 1 says the Brit lives in the red house.

House 1 is Norwegian, so house 1 cannot be red/Brit.

Therefore:

- House 3: red
- House 3: Brit
- House 1: yellow

Clue 7 says the owner of the yellow house smokes Dunhill.

Therefore:

- House 1: smokes Dunhill

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color | yellow | blue | red | green | white |
| Nationality | Norwegian |  | Brit |  |  |
| Drink |  |  | milk | coffee |  |
| Smoke | Dunhill |  |  |  |  |

---

### 5. Place the horse

Clue 11 says the man who keeps a horse lives next to the one who smokes Dunhill.

House 1 smokes Dunhill, so the horse must be in house 2.

- House 2: horse

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color | yellow | blue | red | green | white |
| Nationality | Norwegian |  | Brit |  |  |
| Drink |  |  | milk | coffee |  |
| Pet |  | horse |  |  |  |
| Smoke | Dunhill |  |  |  |  |

---

### 6. Determine possible nationalities

The remaining nationalities are:

- Dane
- German
- Swede

They must go in houses 2, 4, and 5.

Clue 2 says the Swede keeps a dog. House 2 has a horse, so house 2 cannot be the Swede.

Clue 3 says the Dane drinks tea. House 4 drinks coffee, so house 4 cannot be the Dane.

Thus house 2 is either the Dane or the German.

---

### 7. Test whether house 2 is the German

Suppose house 2 is the German.

Clue 13 says the German smokes Prince.

So:

- House 2: German
- House 2: smokes Prince

Then the Dane must be in house 5, because house 4 drinks coffee and cannot be the Dane.

So:

- House 5: Dane
- House 5: drinks tea

The remaining drinks for houses 1 and 2 are beer and water.

But house 2 smokes Prince, so house 2 cannot smoke Blue Master.

Clue 12 says the man who smokes Blue Master drinks beer.

Therefore house 2 cannot drink beer, so house 2 must drink water and house 1 must drink beer.

But house 1 smokes Dunhill, not Blue Master, so house 1 cannot drink beer.

Contradiction.

Therefore:

- House 2 is **not** the German.

So house 2 must be the Dane.

- House 2: Dane
- House 2: drinks tea

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color | yellow | blue | red | green | white |
| Nationality | Norwegian | Dane | Brit |  |  |
| Drink |  | tea | milk | coffee |  |
| Pet |  | horse |  |  |  |
| Smoke | Dunhill |  |  |  |  |

---

### 8. Place beer and water

The remaining drinks are beer and water, for houses 1 and 5.

Clue 12 says the man who smokes Blue Master drinks beer.

House 1 smokes Dunhill, so house 1 cannot smoke Blue Master.

Therefore house 1 cannot drink beer.

So:

- House 5: drinks beer
- House 5: smokes Blue Master
- House 1: drinks water

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color | yellow | blue | red | green | white |
| Nationality | Norwegian | Dane | Brit |  |  |
| Drink | water | tea | milk | coffee | beer |
| Pet |  | horse |  |  |  |
| Smoke | Dunhill |  |  |  | Blue Master |

---

### 9. Use the Blend clues

Clue 15 says the man who smokes Blend has a neighbor who drinks water.

House 1 drinks water. Its only neighbor is house 2.

Therefore:

- House 2: smokes Blend

Clue 10 says the man who smokes Blend lives next to the one who keeps a cat.

House 2 smokes Blend, so the cat is in house 1 or house 3.

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color | yellow | blue | red | green | white |
| Nationality | Norwegian | Dane | Brit |  |  |
| Drink | water | tea | milk | coffee | beer |
| Pet |  | horse |  |  |  |
| Smoke | Dunhill | Blend |  |  | Blue Master |

---

### 10. Place the remaining cigarette brands

The remaining cigarette brands are:

- Pall Mall
- Prince

They must go in houses 3 and 4.

Clue 13 says the German smokes Prince.

House 3 is the Brit, so house 3 cannot be the German.

Therefore:

- House 4: German
- House 4: smokes Prince
- House 3: smokes Pall Mall

Clue 6 says the person who smokes Pall Mall keeps a bird.

Therefore:

- House 3: bird

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color | yellow | blue | red | green | white |
| Nationality | Norwegian | Dane | Brit | German |  |
| Drink | water | tea | milk | coffee | beer |
| Pet |  | horse | bird |  |  |
| Smoke | Dunhill | Blend | Pall Mall | Prince | Blue Master |

---

### 11. Place the Swede and the dog

The only remaining nationality is the Swede, so:

- House 5: Swede

Clue 2 says the Swede keeps a dog.

Therefore:

- House 5: dog

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color | yellow | blue | red | green | white |
| Nationality | Norwegian | Dane | Brit | German | Swede |
| Drink | water | tea | milk | coffee | beer |
| Pet |  | horse | bird |  | dog |
| Smoke | Dunhill | Blend | Pall Mall | Prince | Blue Master |

---

### 12. Place the cat and the fish

The remaining pets are cat and fish, for houses 1 and 4.

Clue 10 says the Blend smoker lives next to the cat.

House 2 smokes Blend. Its neighbors are houses 1 and 3.

House 3 has a bird, so the cat must be in house 1.

Therefore:

- House 1: cat
- House 4: fish

Final grid:

| House | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Color | yellow | blue | red | green | white |
| Nationality | Norwegian | Dane | Brit | German | Swede |
| Drink | water | tea | milk | coffee | beer |
| Pet | cat | horse | bird | fish | dog |
| Smoke | Dunhill | Blend | Pall Mall | Prince | Blue Master |

---

## Answers

1. **Who drinks water?**  
   The **Norwegian**, in house 1.

2. **Who owns the fish?**  
   The **German**, in house 4.
```