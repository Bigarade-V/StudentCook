import { Recipe } from './Recipe'

/**
 * WaterFlow + LazyForEach 懒加载数据源, 实现 IDataSource 接口
 */
export class RecipeDataSource implements IDataSource {
  private listeners: DataChangeListener[] = []
  private recipes: Recipe[] = []

  constructor(recipes: Recipe[]) {
    this.recipes = recipes
  }

  totalCount(): number {
    return this.recipes.length
  }

  getData(index: number): Recipe {
    return this.recipes[index]
  }

  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      this.listeners.push(listener)
    }
  }

  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos: number = this.listeners.indexOf(listener)
    if (pos >= 0) {
      this.listeners.splice(pos, 1)
    }
  }

  /**
   * 整体刷新数据 (搜索过滤), 通知 LazyForEach 重载
   */
  update(recipes: Recipe[]): void {
    this.recipes = recipes
    for (const listener of this.listeners) {
      listener.onDataReloaded()
    }
  }
}
