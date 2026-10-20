import { preferences } from '@kit.ArkData'
import { BusinessError } from '@kit.BasicServicesKit'
import { Context } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const PREF_NAME: string = 'favorites_store'
const KEY_FAVORITE_IDS: string = 'favoriteIds'
const APP_STORAGE_FAVORITES: string = 'favoriteIds'
const LOG_DOMAIN: number = 0x0000
const LOG_TAG: string = 'FavoritesStore'

/**
 * 收藏本地持久化 (preferences), 并通过 AppStorage('favoriteIds') 向 UI 广播变化
 */
export class FavoritesStore {
  private static instance: FavoritesStore | null = null
  private pref: preferences.Preferences | null = null
  private ids: Set<string> = new Set<string>()

  private constructor() {
    const empty: string[] = []
    AppStorage.setOrCreate(APP_STORAGE_FAVORITES, empty)
  }

  /**
   * 应用启动时调用 (EntryAbility.onCreate), 传入 Context 完成同步加载
   */
  static init(context: Context): void {
    if (FavoritesStore.instance === null) {
      FavoritesStore.instance = new FavoritesStore()
      FavoritesStore.instance.load(context)
    }
  }

  /**
   * 页面侧获取已初始化的实例; 若尚未 init 返回 null (正常流程不会发生)
   */
  static peek(): FavoritesStore | null {
    return FavoritesStore.instance
  }

  private load(context: Context): void {
    try {
      const p: preferences.Preferences = preferences.getPreferencesSync(context, { name: PREF_NAME })
      this.pref = p
      const raw: preferences.ValueType = p.getSync(KEY_FAVORITE_IDS, '')
      this.ids = new Set<string>()
      if (typeof raw === 'string' && raw !== '') {
        const parts: string[] = raw.split(',')
        for (const id of parts) {
          if (id !== '') {
            this.ids.add(id)
          }
        }
      }
      this.syncToAppStorage()
    } catch (error) {
      const err = error as BusinessError
      hilog.error(LOG_DOMAIN, LOG_TAG, 'load favorites failed: %{public}s', err.message)
    }
  }

  isFavorite(id: string): boolean {
    return this.ids.has(id)
  }

  toggle(id: string): void {
    if (this.ids.has(id)) {
      this.ids.delete(id)
    } else {
      this.ids.add(id)
    }
    this.persist()
    this.syncToAppStorage()
  }

  private persist(): void {
    const p: preferences.Preferences | null = this.pref
    if (p === null) {
      return
    }
    const arr: string[] = []
    this.ids.forEach((id: string) => {
      arr.push(id)
    })
    try {
      p.putSync(KEY_FAVORITE_IDS, arr.join(','))
      p.flushSync()
    } catch (error) {
      const err = error as BusinessError
      hilog.error(LOG_DOMAIN, LOG_TAG, 'persist favorites failed: %{public}s', err.message)
    }
  }

  private syncToAppStorage(): void {
    const arr: string[] = []
    this.ids.forEach((id: string) => {
      arr.push(id)
    })
    AppStorage.setOrCreate(APP_STORAGE_FAVORITES, arr)
  }
}
