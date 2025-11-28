<template>
  <div class="article-edit">
    <el-card>
      <template #header>
        <span>{{ isEdit ? '编辑文章' : '创建文章' }}</span>
      </template>

      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="标题" prop="title">
          <el-input v-model="form.title" placeholder="请输入文章标题" />
        </el-form-item>

        <el-form-item label="分类" prop="category_id">
          <el-select v-model="form.category_id" placeholder="请选择分类">
            <el-option
              v-for="item in categories"
              :key="item.id"
              :label="item.name"
              :value="item.id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="标签" prop="tag_ids">
          <el-select v-model="form.tag_ids" multiple placeholder="请选择标签">
            <el-option
              v-for="item in tags"
              :key="item.id"
              :label="item.name"
              :value="item.id"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="章节">
          <el-select v-model="form.chapter_id" placeholder="请选择章节(可选)" clearable filterable>
            <el-option
              v-for="item in flatChapters"
              :key="item.id"
              :label="item.displayName"
              :value="item.id"
            >
              <span :style="{ paddingLeft: item.level === 2 ? '20px' : '0' }">
                {{ item.level === 2 ? '└─ ' : '' }}{{ item.name }}
              </span>
              <span v-if="item.tag" style="float: right; color: #8492a6; font-size: 13px">{{ item.tag.name }}</span>
            </el-option>
          </el-select>
          <div style="color: #909399; font-size: 12px; margin-top: 5px;">
            带 └─ 符号的为二级章节
          </div>
        </el-form-item>

        <el-form-item label="摘要" prop="summary">
          <el-input v-model="form.summary" type="textarea" :rows="3" placeholder="请输入文章摘要" />
        </el-form-item>

        <el-form-item label="封面" prop="cover">
          <div class="cover-uploader-wrapper">
            <!-- 当前封面预览 -->
            <div v-if="form.cover" class="cover-preview">
              <img :src="form.cover" class="cover-image" />
              <div class="cover-actions">
                <el-button type="primary" size="small" @click="showCoverSelector">选择封面</el-button>
                <el-button type="danger" size="small" @click="removeCover">移除封面</el-button>
              </div>
            </div>

            <!-- 未选择封面时显示选择按钮 -->
            <div v-else class="cover-placeholder" @click="showCoverSelector">
              <el-icon class="cover-icon"><Plus /></el-icon>
              <div class="cover-text">点击选择封面</div>
            </div>

            <div class="upload-tip">建议上传 16:9 比例的图片，大小不超过 2MB</div>
          </div>
        </el-form-item>

    <!-- 封面选择对话框 -->
    <el-dialog
      v-model="coverDialogVisible"
      title="选择封面"
      width="900px"
      :close-on-click-modal="false"
    >
      <el-tabs v-model="activeTab">
        <!-- 从已上传文件选择 -->
        <el-tab-pane label="从文件库选择" name="library">
          <div class="file-library">
            <div class="library-filters">
              <el-input
                v-model="fileSearch"
                placeholder="搜索文件名"
                clearable
                style="width: 200px"
                @input="fetchFiles"
              />
              <el-button type="primary" @click="fetchFiles">刷新</el-button>
            </div>

            <div v-loading="filesLoading" class="files-grid">
              <div
                v-for="file in imageFiles"
                :key="file.id"
                :class="['file-item', { selected: selectedFile?.id === file.id }]"
                @click="selectFile(file)"
              >
                <img :src="file.url" :alt="file.name" />
                <div class="file-name">{{ file.name }}</div>
              </div>

              <el-empty v-if="!filesLoading && imageFiles.length === 0" description="暂无图片文件" />
            </div>

            <el-pagination
              v-if="fileTotal > 0"
              v-model:current-page="filePage"
              v-model:page-size="filePageSize"
              :total="fileTotal"
              layout="total, prev, pager, next"
              @current-change="fetchFiles"
              style="margin-top: 20px; justify-content: center"
            />
          </div>
        </el-tab-pane>

        <!-- 上传新文件 -->
        <el-tab-pane label="上传新图片" name="upload">
          <div class="upload-area">
            <el-upload
              :action="uploadAction"
              :headers="uploadHeaders"
              :show-file-list="true"
              :on-success="handleUploadSuccess"
              :before-upload="beforeCoverUpload"
              accept="image/*"
              drag
            >
              <el-icon class="el-icon--upload"><UploadFilled /></el-icon>
              <div class="el-upload__text">
                将图片拖到此处，或<em>点击上传</em>
              </div>
              <template #tip>
                <div class="el-upload__tip">
                  支持 jpg/png/gif 格式，建议 16:9 比例，大小不超过 2MB
                </div>
              </template>
            </el-upload>
          </div>
        </el-tab-pane>
      </el-tabs>

      <template #footer>
        <el-button @click="coverDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmCoverSelection" :disabled="!selectedFile && activeTab === 'library'">
          确定
        </el-button>
      </template>
    </el-dialog>

        <el-form-item label="内容" prop="content_markdown">
          <MarkdownEditor v-model="form.content_markdown" />
        </el-form-item>

        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio :value="0">草稿</el-radio>
            <el-radio :value="1">发布</el-radio>
          </el-radio-group>
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleSubmit" :loading="submitting">
            {{ isEdit ? '更新' : '创建' }}
          </el-button>
          <el-button @click="$router.back()">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getArticle, createArticle, updateArticle } from '@/api/article'
import { getTags, getCategories } from '@/api/taxonomy'
import { getChapters } from '@/api/chapter'
import { getFiles } from '@/api/file'
import { ElMessage } from 'element-plus'
import { Plus, UploadFilled } from '@element-plus/icons-vue'
import { useUserStore } from '@/stores/user'
import MarkdownEditor from '@/components/MarkdownEditor.vue'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const formRef = ref()
const submitting = ref(false)
const tags = ref([])
const categories = ref([])
const chapters = ref([])

// 封面选择对话框相关
const coverDialogVisible = ref(false)
const activeTab = ref('library')
const filesLoading = ref(false)
const imageFiles = ref([])
const selectedFile = ref(null)
const fileSearch = ref('')
const filePage = ref(1)
const filePageSize = ref(12)
const fileTotal = ref(0)

const isEdit = computed(() => !!route.params.id)

// 将章节列表转换为扁平化的层级列表
const flatChapters = computed(() => {
  const result = []

  // 先获取所有一级章节（没有父章节的）
  const topLevelChapters = chapters.value.filter(c => !c.parent_id)

  // 对每个一级章节，添加它和它的子章节
  topLevelChapters.forEach(chapter => {
    // 添加一级章节
    result.push({
      ...chapter,
      level: 1,
      displayName: chapter.name
    })

    // 查找该一级章节的所有子章节
    const subChapters = chapters.value.filter(c => c.parent_id === chapter.id)
    subChapters.forEach(subChapter => {
      result.push({
        ...subChapter,
        level: 2,
        displayName: `  └─ ${subChapter.name}`
      })
    })
  })

  return result
})

// 上传配置
const uploadAction = computed(() => '/api/files/upload')
const uploadHeaders = computed(() => ({
  Authorization: `Bearer ${userStore.token}`
}))

const form = reactive({
  title: '',
  content_markdown: '',
  summary: '',
  cover: '',
  category_id: null,
  tag_ids: [],
  chapter_id: null,
  status: 0
})

const rules = {
  title: [{ required: true, message: '请输入标题', trigger: 'blur' }],
  content_markdown: [{ required: true, message: '请输入内容', trigger: 'blur' }],
  category_id: [{ required: true, message: '请选择分类', trigger: 'change' }]
}

const fetchData = async () => {
  const [tagsRes, categoriesRes, chaptersRes] = await Promise.all([
    getTags(),
    getCategories(),
    getChapters()
  ])
  tags.value = tagsRes.data
  categories.value = categoriesRes.data
  chapters.value = chaptersRes.data || []

  if (isEdit.value) {
    const res = await getArticle(route.params.id)
    const article = res.data
    Object.assign(form, {
      title: article.title,
      content_markdown: article.content_markdown,
      summary: article.summary,
      cover: article.cover,
      category_id: article.category_id,
      tag_ids: article.tags?.map(t => t.id) || [],
      chapter_id: article.chapter_id,
      status: article.status
    })
  }
}

// 封面上传前校验
const beforeCoverUpload = (file) => {
  const isImage = file.type.startsWith('image/')
  const isLt2M = file.size / 1024 / 1024 < 2

  if (!isImage) {
    ElMessage.error('只能上传图片文件!')
    return false
  }
  if (!isLt2M) {
    ElMessage.error('图片大小不能超过 2MB!')
    return false
  }
  return true
}

// 显示封面选择器
const showCoverSelector = () => {
  coverDialogVisible.value = true
  activeTab.value = 'library'
  selectedFile.value = null
  fetchFiles()
}

// 获取文件列表
const fetchFiles = async () => {
  filesLoading.value = true
  try {
    const params = {
      page: filePage.value,
      page_size: filePageSize.value,
      type: 'image'
    }

    if (fileSearch.value) {
      params.keyword = fileSearch.value
    }

    const res = await getFiles(params)
    imageFiles.value = res.data.list || []
    fileTotal.value = res.data.total || 0
  } catch (error) {
    ElMessage.error('获取文件列表失败')
  } finally {
    filesLoading.value = false
  }
}

// 选择文件
const selectFile = (file) => {
  selectedFile.value = file
}

// 确认选择封面
const confirmCoverSelection = () => {
  if (activeTab.value === 'library' && selectedFile.value) {
    form.cover = selectedFile.value.url
    ElMessage.success('封面已选择')
    coverDialogVisible.value = false
  }
}

// 移除封面
const removeCover = () => {
  form.cover = ''
}

// 上传新图片成功后
const handleUploadSuccess = (response) => {
  if (response.code === 0) {
    form.cover = response.data.url
    ElMessage.success('封面上传成功')
    coverDialogVisible.value = false
  } else {
    ElMessage.error(response.message || '上传失败')
  }
}

// 封面上传成功(旧的,保留兼容)
const handleCoverSuccess = (response) => {
  handleUploadSuccess(response)
}

const handleSubmit = async () => {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return

  // 验证分类必填
  if (!form.category_id) {
    ElMessage.warning('请选择分类')
    return
  }

  submitting.value = true
  try {
    // 准备提交数据
    const submitData = {
      title: form.title,
      content_markdown: form.content_markdown,
      summary: form.summary,
      cover: form.cover,
      category_id: form.category_id,
      tag_ids: form.tag_ids || [],
      chapter_id: form.chapter_id || null,
      status: form.status
    }

    if (isEdit.value) {
      await updateArticle(route.params.id, submitData)
      ElMessage.success('更新成功')
    } else {
      await createArticle(submitData)
      ElMessage.success('创建成功')
    }
    router.push('/articles')
  } catch (error) {
    ElMessage.error(error.response?.data?.message || '操作失败')
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  fetchData()
})
</script>

<style scoped>
.article-edit {
  max-width: 1400px;
}

.article-edit :deep(.el-form-item__content) {
  line-height: normal;
}

.cover-uploader-wrapper {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.cover-uploader :deep(.el-upload) {
  border: 1px dashed #d9d9d9;
  border-radius: 6px;
  cursor: pointer;
  position: relative;
  overflow: hidden;
  transition: border-color 0.3s;
  width: 360px;
  height: 202px;
}

.cover-uploader :deep(.el-upload:hover) {
  border-color: #409eff;
}

.cover-placeholder {
  width: 360px;
  height: 202px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  color: #8c939d;
  border: 1px dashed #d9d9d9;
  border-radius: 6px;
  cursor: pointer;
  transition: border-color 0.3s;
}

.cover-placeholder:hover {
  border-color: #409eff;
}

.cover-preview {
  width: 360px;
  height: 202px;
  position: relative;
  border: 1px solid #d9d9d9;
  border-radius: 6px;
  overflow: hidden;
}

.cover-preview .cover-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.cover-preview .cover-actions {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, 0.6);
  padding: 8px;
  display: flex;
  gap: 8px;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.3s;
}

.cover-preview:hover .cover-actions {
  opacity: 1;
}

.cover-icon {
  font-size: 28px;
}

.cover-text {
  font-size: 14px;
}

.upload-tip {
  font-size: 12px;
  color: #909399;
}

/* 封面选择对话框样式 */
.file-library {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.library-filters {
  display: flex;
  gap: 12px;
  align-items: center;
}

.files-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 16px;
  min-height: 300px;
  max-height: 500px;
  overflow-y: auto;
  padding: 8px;
}

.file-item {
  position: relative;
  cursor: pointer;
  border: 2px solid transparent;
  border-radius: 8px;
  overflow: hidden;
  transition: all 0.3s;
  aspect-ratio: 16 / 9;
  background: #f5f7fa;
}

.file-item:hover {
  border-color: #409eff;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(64, 158, 255, 0.3);
}

.file-item.selected {
  border-color: #409eff;
  box-shadow: 0 0 0 3px rgba(64, 158, 255, 0.2);
}

.file-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.file-name {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(0, 0, 0, 0.7);
  color: #fff;
  padding: 4px 8px;
  font-size: 12px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.upload-area {
  padding: 20px;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 300px;
}
</style>
