export class Recipe {
  readonly id: string
  readonly name: string
  readonly category: string
  readonly ingredients: string[]
  readonly steps: string[]
  readonly imageUrl: string
  readonly difficulty: number
  readonly cookingTime: string

  constructor(id: string, name: string, category: string, ingredients: string[],
    steps: string[], imageUrl: string, difficulty: number, cookingTime: string) {
    this.id = id
    this.name = name
    this.category = category
    this.ingredients = ingredients
    this.steps = steps
    this.imageUrl = imageUrl
    this.difficulty = difficulty
    this.cookingTime = cookingTime
  }

  static stars(count: number): string {
    let result: string = ''
    for (let i = 0; i < count; i++) {
      result += '★'
    }
    return result
  }
}
