<div class="row">
    <div class="col-md-3">
        <?php include 'sidebar.php'; ?>
    </div>
    <div class="col-md-9">
        <section class="panel">
            <?php echo form_open('school_settings/student_parent_panel' . get_request_url(), array('class' => 'form-horizontal form-bordered frm-submit-msg')); ?>
            <header class="panel-heading">
                <h4 class="panel-title"><i class="fa-solid fa-users"></i> <?php echo translate('student_parent_panel'); ?></h4>
            </header>
            
            <div class="panel-body">  
                <section class="panel pg-fw">
                    <div class="panel-body">
                        <h5 class="chart-title mb-xs"><?php echo translate('user') . " " . translate('login'); ?></h5>
                        <div class="mt-md">
                            <div class="form-group mt-md">
                                <label class="col-md-3 control-label"><?php echo translate('student') . " " . translate('login'); ?> <span class="required">*</span></label>
                                <div class="col-md-7">
                                    <?php
                                        $arrayData = array(
                                            "1"  => translate('yes'),
                                            "0"  => translate('no'),
                                        );
                                        echo form_dropdown("student_login", $arrayData, set_value('student_login', $school['student_login']), "class='form-control'
                                        data-plugin-selectTwo data-width='100%' data-minimum-results-for-search='Infinity' ");
                                    ?>
                                    <span class="error"></span>
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="col-md-3 control-label"><?php echo translate('parent') . " " . translate('login'); ?> <span class="required">*</span></label>
                                <div class="col-md-7 mb-md">
                                    <?php
                                        $arrayData = array(
                                            "1"  => translate('yes'),
                                            "0"  => translate('no'),
                                        );
                                        echo form_dropdown("parent_login", $arrayData, set_value('parent_login', $school['parent_login']), "class='form-control'
                                        data-plugin-selectTwo data-width='100%' data-minimum-results-for-search='Infinity' ");
                                    ?>
                                    <span class="error"></span>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
                <section class="panel pg-fw">
                    <div class="panel-body">
                        <h5 class="chart-title mb-xs"><?php echo translate('privacy'); ?></h5>
                        <div class="mt-md">
                            <div class="form-group">
                                <div class="col-md-offset-3 col-md-6">
                                    <div class="checkbox-replace">
                                        <label class="i-checks">
                                            <input type="checkbox" <?php echo $school['teacher_mobile_visible'] == 1 ? 'checked' : ''; ?> name="teacher_mobile_visible" id="teacher_mobile_visible"> <i></i> Teachers Mobile Number Visible.
                                        </label>
                                    </div>
                                </div>
                            </div>
                            <div class="form-group">
                                <div class="col-md-offset-3 col-md-6 mb-md">
                                    <div class="checkbox-replace">
                                        <label class="i-checks">
                                            <input type="checkbox" <?php echo $school['teacher_email_visible'] == 1 ? 'checked' : ''; ?> name="teacher_email_visible" id="teacher_email_visible"> <i></i> Teachers Email Visible.
                                        </label>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>
                <section class="panel pg-fw">
                    <div class="panel-body">
                        <h5 class="chart-title mb-xs"><?php echo translate('default_template'); ?></h5>
                        <div class="mt-md">
                            <div class="form-group mt-md">
                                <label class="col-md-3 control-label"><?php echo translate('admit_card') . " " . translate('templete'); ?> <span class="required">*</span></label>
                                <div class="col-md-7">

                                        <?php
                                            $arrayClass = $this->app_lib->getSelectByBranch('card_templete', $branch_id, false, array('user_type' => 1, 'card_type' => 2));
                                            echo form_dropdown("admit_card_id", $arrayClass, set_value('admit_card_id', $school['default_admitcard_temp']), "class='form-control' id='templete_id'
                                            data-plugin-selectTwo data-width='100%' ");
                                        ?>

                                    
                                    <span class="error"></span>
                                </div>
                            </div>
                            <div class="form-group">
                                <label class="col-md-3 control-label"><?php echo translate('marksheet') . " " . translate('template'); ?> <span class="required">*</span></label>
                                <div class="col-md-7 mb-md">
                                    <?php
                                        $arraySection = $this->app_lib->getSelectByBranch('marksheet_template', $branch_id);
                                        echo form_dropdown("marksheet_template_id", $arraySection, set_value('marksheet_template_id', $school['default_marksheet_temp']), "class='form-control' id='templateID'
                                        data-plugin-selectTwo data-width='100%' ");
                                    ?>
                                    <span class="error"></span>
                                </div>
                            </div>
                        </div>
                    </div>
                </section>

            </div>
            <div class="panel-footer">
                <div class="row">
                    <div class="col-md-2 col-sm-offset-3">
                        <button type="submit" class="btn btn btn-default btn-block" data-loading-text="<i class='fas fa-spinner fa-spin'></i> Processing">
                            <i class="fas fa-plus-circle"></i> <?=translate('save');?>
                        </button>
                    </div>
                </div>
            </div>
            </form>
        </section>
    </div>
</div>

