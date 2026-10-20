import { Recipe } from './Recipe'
import recipesRaw from '../data/recipes.json'

export class RecipeRepository {
  private static instance: RecipeRepository | null = null
  private recipes: Recipe[] = []
  private categories: string[] = []
  private byId: Map<string, Recipe> = new Map()
  private byCategory: Map<string, Recipe[]> = new Map()

  private constructor() {
    for (let i = 0; i < recipesRaw.length; i++) {
      const item = recipesRaw[i]
      const recipe: Recipe = new Recipe(item.id, item.name, item.category, item.ingredients,
        item.steps, item.imageUrl, item.difficulty, item.cookingTime)
      this.byId.set(recipe.id, recipe)
      let list: Recipe[] | undefined = this.byCategory.get(recipe.category)
      if (list === undefined) {
        list = []
        this.byCategory.set(recipe.category, list)
        this.categories.push(recipe.category)
      }
      list.push(recipe)
    }
    // 每个分类内部: 有封面图的排前面(稳定排序, 保持原有相对顺序), 避免首屏全是占位块
    for (const cat of this.categories) {
      const list: Recipe[] = this.byCategory.get(cat) ?? []
      const sorted: Recipe[] = list.slice().sort((a: Recipe, b: Recipe): number => {
        const av: number = a.imageUrl !== '' ? 1 : 0
        const bv: number = b.imageUrl !== '' ? 1 : 0
        return bv - av
      })
      this.byCategory.set(cat, sorted)
      this.recipes = this.recipes.concat(sorted)
    }
  }

  static getInstance(): RecipeRepository {
    if (RecipeRepository.instance === null) {
      RecipeRepository.instance = new RecipeRepository()
    }
    return RecipeRepository.instance
  }

  getAll(): Recipe[] {
    return this.recipes
  }

  getById(id: string): Recipe | null {
    return this.byId.get(id) ?? null
  }

  getCategories(): string[] {
    return this.categories
  }

  getByCategory(category: string): Recipe[] {
    return this.byCategory.get(category) ?? []
  }

  search(keyword: string): Recipe[] {
    const kw: string = keyword.trim()
    if (kw === '') {
      return this.recipes
    }
    const result: Recipe[] = []
    for (const recipe of this.recipes) {
      if (recipe.name.includes(kw)) {
        result.push(recipe)
      }
    }
    return result
  }
}
